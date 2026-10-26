//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api_client/src/model/expense_status.dart';
import 'package:api_client/src/model/expense_category.dart';
import 'package:api_client/src/model/task_ref.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'expense.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class Expense {
  /// Returns a new [Expense] instance.
  Expense({
    required this.id,

    required this.reference,

    required this.amount,

    required this.category,

    required this.note,

    required this.spentOn,

    required this.status,

    required this.hasReceipt,

    this.adminNote,

    this.adminName,

    this.task,

    this.receiptUrl,
  });

  /// UUIDv7.
  @JsonKey(name: r'id', required: true, includeIfNull: false)
  final String id;

  @JsonKey(name: r'reference', required: true, includeIfNull: false)
  final String reference;

  /// Amount in paise (₹1 = 100). Never a float.
  @JsonKey(name: r'amount', required: true, includeIfNull: false)
  final int amount;

  @JsonKey(name: r'category', required: true, includeIfNull: false)
  final ExpenseCategory category;

  @JsonKey(name: r'note', required: true, includeIfNull: false)
  final String note;

  @JsonKey(name: r'spent_on', required: true, includeIfNull: false)
  final String spentOn;

  @JsonKey(name: r'status', required: true, includeIfNull: false)
  final ExpenseStatus status;

  @JsonKey(name: r'has_receipt', required: true, includeIfNull: false)
  final bool hasReceipt;

  /// Why it needs a fix.
  @JsonKey(name: r'admin_note', required: false, includeIfNull: false)
  final String? adminNote;

  /// Who decided, when someone has.
  @JsonKey(name: r'admin_name', required: false, includeIfNull: false)
  final String? adminName;

  @JsonKey(name: r'task', required: false, includeIfNull: false)
  final TaskRef? task;

  /// Short-lived link to the receipt photo; `asset:<name>` in sample data.
  @JsonKey(name: r'receipt_url', required: false, includeIfNull: false)
  final String? receiptUrl;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is Expense &&
            runtimeType == other.runtimeType &&
            equals(
              [
                id,
                reference,
                amount,
                category,
                note,
                spentOn,
                status,
                hasReceipt,
                adminNote,
                adminName,
                task,
                receiptUrl,
              ],
              [
                other.id,
                other.reference,
                other.amount,
                other.category,
                other.note,
                other.spentOn,
                other.status,
                other.hasReceipt,
                other.adminNote,
                other.adminName,
                other.task,
                other.receiptUrl,
              ],
            );
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^
      mapPropsToHashCode([
        id,
        reference,
        amount,
        category,
        note,
        spentOn,
        status,
        hasReceipt,
        adminNote,
        adminName,
        task,
        receiptUrl,
      ]);

  factory Expense.fromJson(Map<String, dynamic> json) =>
      _$ExpenseFromJson(json);

  Map<String, dynamic> toJson() => _$ExpenseToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
