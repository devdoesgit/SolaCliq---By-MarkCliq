import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:solacliq/auth/auth.dart';
import 'package:solacliq/expenses/data/expense_repository.dart';
import 'package:solacliq/expenses/view/expense_page.dart';
import 'package:solacliq/uploads/data/upload_repository.dart';
import 'package:solacliq/workspace/data/workspace.dart';

import '../helpers/helpers.dart';

void main() {
  late MockExpenseRepository expenses;
  final workspace = MemberWorkspace(testMembership());

  setUpAll(() => registerFallbackValue(ExpenseCategory.fuel));

  setUp(() {
    expenses = MockExpenseRepository();
    when(
      () => expenses.create(
        orgId: any(named: 'orgId'),
        idempotencyKey: any(named: 'idempotencyKey'),
        amountPaise: any(named: 'amountPaise'),
        category: any(named: 'category'),
        note: any(named: 'note'),
        spentOn: any(named: 'spentOn'),
        receiptUploadId: any(named: 'receiptUploadId'),
      ),
    ).thenAnswer(
      (_) async => Expense(
        id: 'e1',
        reference: 'EXP-1',
        amountPaise: 124000,
        category: ExpenseCategory.fuel,
        note: 'Diesel',
        spentOn: DateTime(2026, 10, 23),
        status: ExpenseStatus.inReview,
        hasReceipt: false,
      ),
    );
  });

  Future<void> pump(WidgetTester tester) => tester.pumpApp(
    ExpensePage(workspace: workspace),
    repositories: [
      RepositoryProvider<ExpenseRepository>.value(value: expenses),
      RepositoryProvider<UploadRepository>.value(value: MockUploadRepository()),
    ],
  );

  Future<void> type(WidgetTester tester, String keys) async {
    for (final k in keys.split('')) {
      await tester.tap(find.byKey(ValueKey('keypad_$k')));
      await tester.pump();
    }
  }

  group(ExpensePage, () {
    testWidgets('the keypad types the amount', (tester) async {
      await pump(tester);
      await type(tester, '1240');
      expect(find.text('₹1,240'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('keypad_delete')));
      await tester.pump();
      expect(find.text('₹124'), findsOneWidget);
    });

    testWidgets('asks for the amount, category and note', (tester) async {
      await pump(tester);
      await tester.tapKey('expense_submit');
      await tester.pump();
      expect(find.text('Enter the amount.'), findsOneWidget);
      expect(find.text('Choose one.'), findsOneWidget);
      expect(find.text('Say what it was for.'), findsOneWidget);
      verifyNever(
        () => expenses.create(
          orgId: any(named: 'orgId'),
          idempotencyKey: any(named: 'idempotencyKey'),
          amountPaise: any(named: 'amountPaise'),
          category: any(named: 'category'),
          note: any(named: 'note'),
          spentOn: any(named: 'spentOn'),
        ),
      );
    });

    testWidgets('sends paise to the admin and moves on', (tester) async {
      await pump(tester);
      await type(tester, '1240.5');
      await tester.tapKey('expense_category_0');
      await tester.enterText(
        find.descendant(
          of: find.byKey(const ValueKey('expense_note')),
          matching: find.byType(TextField),
        ),
        ' Diesel ',
      );
      await tester.tapKey('expense_submit');
      await tester.pumpAndSettle();
      verify(
        () => expenses.create(
          orgId: 'o1',
          idempotencyKey: any(named: 'idempotencyKey'),
          amountPaise: 124050,
          category: ExpenseCategory.fuel,
          note: 'Diesel',
          spentOn: any(named: 'spentOn'),
        ),
      ).called(1);
      expect(find.text('route:/expense/sent'), findsOneWidget);
    });

    testWidgets('a failure is shown and can be sent again', (tester) async {
      when(
        () => expenses.create(
          orgId: any(named: 'orgId'),
          idempotencyKey: any(named: 'idempotencyKey'),
          amountPaise: any(named: 'amountPaise'),
          category: any(named: 'category'),
          note: any(named: 'note'),
          spentOn: any(named: 'spentOn'),
        ),
      ).thenThrow(const AuthFailure(AuthFailureCode.network));
      await pump(tester);
      await type(tester, '5');
      await tester.tapKey('expense_category_1');
      await tester.enterText(
        find.descendant(
          of: find.byKey(const ValueKey('expense_note')),
          matching: find.byType(TextField),
        ),
        'Cable',
      );
      await tester.tapKey('expense_submit');
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('failure_notice')), findsOneWidget);
    });
  });
}
