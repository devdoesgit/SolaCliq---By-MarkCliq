//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api_client/src/model/my_document.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'my_document_list.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class MyDocumentList {
  /// Returns a new [MyDocumentList] instance.
  MyDocumentList({required this.items, this.uploadedBy});

  @JsonKey(name: r'items', required: true, includeIfNull: false)
  final List<MyDocument> items;

  /// The agent who collected a customer's KYC.
  @JsonKey(name: r'uploaded_by', required: false, includeIfNull: false)
  final String? uploadedBy;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is MyDocumentList &&
            runtimeType == other.runtimeType &&
            equals([items, uploadedBy], [other.items, other.uploadedBy]);
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^ mapPropsToHashCode([items, uploadedBy]);

  factory MyDocumentList.fromJson(Map<String, dynamic> json) =>
      _$MyDocumentListFromJson(json);

  Map<String, dynamic> toJson() => _$MyDocumentListToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
