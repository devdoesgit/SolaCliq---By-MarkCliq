//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api_client/src/model/kyc_kind.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'customer_registration_create_documents_inner.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class CustomerRegistrationCreateDocumentsInner {
  /// Returns a new [CustomerRegistrationCreateDocumentsInner] instance.
  CustomerRegistrationCreateDocumentsInner({
    required this.kind,

    required this.uploadId,
  });

  @JsonKey(name: r'kind', required: true, includeIfNull: false)
  final KycKind kind;

  /// UUIDv7.
  @JsonKey(name: r'upload_id', required: true, includeIfNull: false)
  final String uploadId;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is CustomerRegistrationCreateDocumentsInner &&
            runtimeType == other.runtimeType &&
            equals([kind, uploadId], [other.kind, other.uploadId]);
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^ mapPropsToHashCode([kind, uploadId]);

  factory CustomerRegistrationCreateDocumentsInner.fromJson(
    Map<String, dynamic> json,
  ) => _$CustomerRegistrationCreateDocumentsInnerFromJson(json);

  Map<String, dynamic> toJson() =>
      _$CustomerRegistrationCreateDocumentsInnerToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
