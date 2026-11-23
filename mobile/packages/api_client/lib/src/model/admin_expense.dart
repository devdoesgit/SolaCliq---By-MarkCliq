//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api_client/src/model/expense_status.dart';
import 'package:api_client/src/model/expense_category.dart';
import 'package:api_client/src/model/task_ref.dart';
import 'package:api_client/src/model/admin_file.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'admin_expense.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AdminExpense {
  /// Returns a new [AdminExpense] instance.
  AdminExpense({
    required this.id,

    required this.reference,

    required this.ownerName,

    required this.amount,

    required this.category,

    required this.note,

    required this.spentOn,

    required this.status,

    required this.hasReceipt,

    required this.createdAt,

    required this.statusAt,

    this.receipt,

    this.adminNote,

    this.fixNote,

    this.adminName,

    this.task,

    this.payoutLast4,
  });

  /// UUIDv7.
  @JsonKey(name: r'id', required: true, includeIfNull: false)
  final String id;

  @JsonKey(name: r'reference', required: true, includeIfNull: false)
  final String reference;

  @JsonKey(name: r'owner_name', required: true, includeIfNull: false)
  final String ownerName;

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

  /// ISO 8601, UTC.
  @JsonKey(name: r'created_at', required: true, includeIfNull: false)
  final DateTime createdAt;

  /// ISO 8601, UTC.
  @JsonKey(name: r'status_at', required: true, includeIfNull: false)
  final DateTime statusAt;

  @JsonKey(name: r'receipt', required: false, includeIfNull: false)
  final AdminFile? receipt;

  @JsonKey(name: r'admin_note', required: false, includeIfNull: false)
  final String? adminNote;

  @JsonKey(name: r'fix_note', required: false, includeIfNull: false)
  final String? fixNote;

  @JsonKey(name: r'admin_name', required: false, includeIfNull: false)
  final String? adminName;

  @JsonKey(name: r'task', required: false, includeIfNull: false)
  final TaskRef? task;

  /// The last 4 digits of the payout account, never more.
  @JsonKey(name: r'payout_last4', required: false, includeIfNull: false)
  final String? payoutLast4;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is AdminExpense &&
            runtimeType == other.runtimeType &&
            equals(
              [
                id,
                reference,
                ownerName,
                amount,
                category,
                note,
                spentOn,
                status,
                hasReceipt,
                createdAt,
                statusAt,
                receipt,
                adminNote,
                fixNote,
                adminName,
                task,
                payoutLast4,
              ],
              [
                other.id,
                other.reference,
                other.ownerName,
                other.amount,
                other.category,
                other.note,
                other.spentOn,
                other.status,
                other.hasReceipt,
                other.createdAt,
                other.statusAt,
                other.receipt,
                other.adminNote,
                other.fixNote,
                other.adminName,
                other.task,
                other.payoutLast4,
              ],
            );
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^
      mapPropsToHashCode([
        id,
        reference,
        ownerName,
        amount,
        category,
        note,
        spentOn,
        status,
        hasReceipt,
        createdAt,
        statusAt,
        receipt,
        adminNote,
        fixNote,
        adminName,
        task,
        payoutLast4,
      ]);

  factory AdminExpense.fromJson(Map<String, dynamic> json) =>
      _$AdminExpenseFromJson(json);

  Map<String, dynamic> toJson() => _$AdminExpenseToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
