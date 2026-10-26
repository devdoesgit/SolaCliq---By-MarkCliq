//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api_client/src/model/document_status.dart';
import 'package:api_client/src/model/kyc_kind.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'my_document.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class MyDocument {
  /// Returns a new [MyDocument] instance.
  MyDocument({required this.kind, this.detail, required this.status});

  @JsonKey(name: r'kind', required: true, includeIfNull: false)
  final KycKind kind;

  @JsonKey(name: r'detail', required: false, includeIfNull: false)
  final String? detail;

  @JsonKey(name: r'status', required: true, includeIfNull: false)
  final DocumentStatus status;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is MyDocument &&
            runtimeType == other.runtimeType &&
            equals(
              [kind, detail, status],
              [other.kind, other.detail, other.status],
            );
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^ mapPropsToHashCode([kind, detail, status]);

  factory MyDocument.fromJson(Map<String, dynamic> json) =>
      _$MyDocumentFromJson(json);

  Map<String, dynamic> toJson() => _$MyDocumentToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
