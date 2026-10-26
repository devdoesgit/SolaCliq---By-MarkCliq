import 'dart:convert';

import 'package:api_client/api_client.dart' show ExpensesApi;
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:solacliq/expenses/data/expense_repository.dart';

import '../helpers/helpers.dart';

void main() {
  final expenseJson = {
    'id': 'e1',
    'reference': 'EXP-1',
    'amount': 124000,
    'category': 'fuel',
    'note': 'Diesel',
    'spent_on': '2026-10-23',
    'status': 'needs_fix',
    'has_receipt': false,
    'admin_note': 'Add the receipt',
  };

  late List<RequestOptions> requests;

  ExpenseRepository repository() {
    requests = [];
    final dio = Dio(BaseOptions(baseUrl: 'http://api'))
      ..httpClientAdapter = FakeAdapter((o) async {
        requests.add(o);
        return o.method == 'POST'
            ? jsonBody(201, expenseJson)
            : jsonBody(200, {
                'items': [expenseJson],
                'page': {'next_cursor': null},
              });
      });
    return ExpenseRepository(ExpensesApi(dio));
  }

  group(ExpenseRepository, () {
    test('sends paise, the day as YYYY-MM-DD and the key', () async {
      final repo = repository();
      final e = await repo.create(
        orgId: 'o1',
        idempotencyKey: 'k1',
        amountPaise: 124000,
        category: ExpenseCategory.fuel,
        note: 'Diesel',
        spentOn: DateTime(2026, 10, 23, 18, 30),
        receiptUploadId: 'up-1',
      );
      final sent = requests.single;
      expect(sent.path, '/orgs/o1/expenses');
      expect(sent.headers['Idempotency-Key'], 'k1');
      final data = sent.data;
      final body =
          (data is String ? jsonDecode(data) : data) as Map<String, Object?>;
      expect(body['spent_on'], '2026-10-23');
      expect(body['amount'], 124000);
      expect(body['receipt_upload_id'], 'up-1');
      expect(e.reference, 'EXP-1');
    });

    test('reads the list, statuses and notes', () async {
      final items = await repository().mine('o1');
      expect(items.single.status, ExpenseStatus.needsFix);
      expect(items.single.spentOn, DateTime(2026, 10, 23));
      expect(items.single.adminNote, 'Add the receipt');
    });
  });
}
