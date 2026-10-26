//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'replace_customer_document_request.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ReplaceCustomerDocumentRequest {
  /// Returns a new [ReplaceCustomerDocumentRequest] instance.
  ReplaceCustomerDocumentRequest({required this.uploadId});

  /// UUIDv7.
  @JsonKey(name: r'upload_id', required: true, includeIfNull: false)
  final String uploadId;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is ReplaceCustomerDocumentRequest &&
            runtimeType == other.runtimeType &&
            equals([uploadId], [other.uploadId]);
  }

  @override
  int get hashCode => runtimeType.hashCode ^ mapPropsToHashCode([uploadId]);

  factory ReplaceCustomerDocumentRequest.fromJson(Map<String, dynamic> json) =>
      _$ReplaceCustomerDocumentRequestFromJson(json);

  Map<String, dynamic> toJson() => _$ReplaceCustomerDocumentRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
