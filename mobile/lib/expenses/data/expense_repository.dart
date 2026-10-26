import 'package:api_client/api_client.dart' as api;
import 'package:equatable/equatable.dart';
import 'package:solacliq/app/data/api_call.dart';

enum ExpenseCategory { fuel, material, labour, other }

enum ExpenseStatus { inReview, approved, needsFix, paid }

/// A cost a worker or agent sent to their admin.
class Expense extends Equatable {
  const new({
    required this.id,
    required this.reference,
    required this.amountPaise,
    required this.category,
    required this.note,
    required this.spentOn,
    required this.status,
    required this.hasReceipt,
    this.adminNote,
    this.adminName,
    this.taskTitle,
    this.taskCustomer,
    this.receiptUrl,
  });

  final String id;

  /// "EXP-2291".
  final String reference;
  final int amountPaise;
  final ExpenseCategory category;
  final String note;
  final DateTime spentOn;
  final ExpenseStatus status;
  final bool hasReceipt;
  final String? adminNote;

  /// Who decided, once someone has.
  final String? adminName;

  /// The task it was spent on, if any.
  final String? taskTitle;
  final String? taskCustomer;

  /// A short-lived link, or `asset:<name>` in sample data.
  final String? receiptUrl;

  @override
  List<Object?> get props => [
    id,
    reference,
    amountPaise,
    category,
    note,
    spentOn,
    status,
    hasReceipt,
    adminNote,
    adminName,
    taskTitle,
    taskCustomer,
    receiptUrl,
  ];
}

/// The person's own expenses in one company.
class ExpenseRepository {
  new(this._api);

  final api.ExpensesApi _api;

  /// The latest first.
  Future<List<Expense>> mine(String orgId) async {
    final response = await apiCall(() => _api.listMyExpenses(orgId: orgId));
    return [for (final e in response.data!.items) _expense(e)];
  }

  /// Sends an expense to the admin. Pass the same [idempotencyKey] when
  /// retrying, so a retry never logs it twice.
  Future<Expense> create({
    required String orgId,
    required String idempotencyKey,
    required int amountPaise,
    required ExpenseCategory category,
    required String note,
    required DateTime spentOn,
    String? receiptUploadId,
    String? taskId,
  }) async {
    final response = await apiCall(
      () => _api.createExpense(
        orgId: orgId,
        idempotencyKey: idempotencyKey,
        expenseCreate: api.ExpenseCreate(
          amount: amountPaise,
          category: api.ExpenseCategory.values.byName(category.name),
          note: note,
          spentOn: _isoDate(spentOn),
          receiptUploadId: receiptUploadId,
          taskId: taskId,
        ),
      ),
    );
    return _expense(response.data!);
  }

  Future<Expense> get(String orgId, String expenseId) async {
    final response = await apiCall(
      () => _api.getExpense(orgId: orgId, expenseId: expenseId),
    );
    return _expense(response.data!);
  }

  /// Sends a clearer receipt for an expense the admin sent back.
  Future<Expense> replaceReceipt({
    required String orgId,
    required String expenseId,
    required String uploadId,
  }) async {
    final response = await apiCall(
      () => _api.replaceExpenseReceipt(
        orgId: orgId,
        expenseId: expenseId,
        replaceExpenseReceiptRequest: api.ReplaceExpenseReceiptRequest(
          uploadId: uploadId,
        ),
      ),
    );
    return _expense(response.data!);
  }

  /// The calendar date as the contract's `YYYY-MM-DD`.
  static String _isoDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  static Expense _expense(api.Expense e) => Expense(
    id: e.id,
    reference: e.reference,
    amountPaise: e.amount,
    category: ExpenseCategory.values.byName(e.category.name),
    note: e.note,
    spentOn: DateTime.parse(e.spentOn),
    status: switch (e.status) {
      api.ExpenseStatus.inReview => ExpenseStatus.inReview,
      api.ExpenseStatus.approved => ExpenseStatus.approved,
      api.ExpenseStatus.needsFix => ExpenseStatus.needsFix,
      api.ExpenseStatus.paid => ExpenseStatus.paid,
    },
    hasReceipt: e.hasReceipt,
    adminNote: e.adminNote,
    adminName: e.adminName,
    taskTitle: e.task?.title,
    taskCustomer: e.task?.customerName,
    receiptUrl: e.receiptUrl,
  );
}
