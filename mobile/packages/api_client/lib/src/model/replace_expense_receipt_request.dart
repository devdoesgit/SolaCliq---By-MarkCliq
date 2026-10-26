//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'replace_expense_receipt_request.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ReplaceExpenseReceiptRequest {
  /// Returns a new [ReplaceExpenseReceiptRequest] instance.
  ReplaceExpenseReceiptRequest({required this.uploadId, this.note});

  /// UUIDv7.
  @JsonKey(name: r'upload_id', required: true, includeIfNull: false)
  final String uploadId;

  @JsonKey(name: r'note', required: false, includeIfNull: false)
  final String? note;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is ReplaceExpenseReceiptRequest &&
            runtimeType == other.runtimeType &&
            equals([uploadId, note], [other.uploadId, other.note]);
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^ mapPropsToHashCode([uploadId, note]);

  factory ReplaceExpenseReceiptRequest.fromJson(Map<String, dynamic> json) =>
      _$ReplaceExpenseReceiptRequestFromJson(json);

  Map<String, dynamic> toJson() => _$ReplaceExpenseReceiptRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
