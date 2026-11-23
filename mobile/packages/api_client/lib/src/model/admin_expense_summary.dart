//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api_client/src/model/expense_status.dart';
import 'package:api_client/src/model/expense_category.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'admin_expense_summary.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AdminExpenseSummary {
  /// Returns a new [AdminExpenseSummary] instance.
  AdminExpenseSummary({
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

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is AdminExpenseSummary &&
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
      ]);

  factory AdminExpenseSummary.fromJson(Map<String, dynamic> json) =>
      _$AdminExpenseSummaryFromJson(json);

  Map<String, dynamic> toJson() => _$AdminExpenseSummaryToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
