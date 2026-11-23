//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api_client/src/model/kyc_kind.dart';
import 'package:api_client/src/model/document_file.dart';
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

    required this.files,
  });

  @JsonKey(name: r'kind', required: true, includeIfNull: false)
  final KycKind kind;

  @JsonKey(name: r'files', required: true, includeIfNull: false)
  final List<DocumentFile> files;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is CustomerRegistrationCreateDocumentsInner &&
            runtimeType == other.runtimeType &&
            equals([kind, files], [other.kind, other.files]);
  }

  @override
  int get hashCode => runtimeType.hashCode ^ mapPropsToHashCode([kind, files]);

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
