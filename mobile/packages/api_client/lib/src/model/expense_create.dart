//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api_client/src/model/expense_category.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'expense_create.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ExpenseCreate {
  /// Returns a new [ExpenseCreate] instance.
  ExpenseCreate({
    required this.amount,

    required this.category,

    required this.note,

    required this.spentOn,

    this.receiptUploadId,

    this.taskId,
  });

  /// Amount in paise (₹1 = 100). Never a float.
  @JsonKey(name: r'amount', required: true, includeIfNull: false)
  final int amount;

  @JsonKey(name: r'category', required: true, includeIfNull: false)
  final ExpenseCategory category;

  @JsonKey(name: r'note', required: true, includeIfNull: false)
  final String note;

  @JsonKey(name: r'spent_on', required: true, includeIfNull: false)
  final String spentOn;

  /// UUIDv7.
  @JsonKey(name: r'receipt_upload_id', required: false, includeIfNull: false)
  final String? receiptUploadId;

  /// The task it was spent on, if any.
  @JsonKey(name: r'task_id', required: false, includeIfNull: false)
  final String? taskId;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is ExpenseCreate &&
            runtimeType == other.runtimeType &&
            equals(
              [amount, category, note, spentOn, receiptUploadId, taskId],
              [
                other.amount,
                other.category,
                other.note,
                other.spentOn,
                other.receiptUploadId,
                other.taskId,
              ],
            );
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^
      mapPropsToHashCode([
        amount,
        category,
        note,
        spentOn,
        receiptUploadId,
        taskId,
      ]);

  factory ExpenseCreate.fromJson(Map<String, dynamic> json) =>
      _$ExpenseCreateFromJson(json);

  Map<String, dynamic> toJson() => _$ExpenseCreateToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
