//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api_client/src/model/document_status.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'customer_detail_documents.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class CustomerDetailDocuments {
  /// Returns a new [CustomerDetailDocuments] instance.
  CustomerDetailDocuments({required this.status, required this.detail});

  @JsonKey(name: r'status', required: true, includeIfNull: false)
  final DocumentStatus status;

  @JsonKey(name: r'detail', required: true, includeIfNull: false)
  final String detail;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is CustomerDetailDocuments &&
            runtimeType == other.runtimeType &&
            equals([status, detail], [other.status, other.detail]);
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^ mapPropsToHashCode([status, detail]);

  factory CustomerDetailDocuments.fromJson(Map<String, dynamic> json) =>
      _$CustomerDetailDocumentsFromJson(json);

  Map<String, dynamic> toJson() => _$CustomerDetailDocumentsToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
