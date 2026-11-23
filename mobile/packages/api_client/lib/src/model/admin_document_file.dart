//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api_client/src/model/document_side.dart';
import 'package:api_client/src/model/admin_file.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'admin_document_file.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AdminDocumentFile {
  /// Returns a new [AdminDocumentFile] instance.
  AdminDocumentFile({required this.file, this.side});

  @JsonKey(name: r'file', required: true, includeIfNull: false)
  final AdminFile file;

  @JsonKey(name: r'side', required: false, includeIfNull: false)
  final DocumentSide? side;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is AdminDocumentFile &&
            runtimeType == other.runtimeType &&
            equals([file, side], [other.file, other.side]);
  }

  @override
  int get hashCode => runtimeType.hashCode ^ mapPropsToHashCode([file, side]);

  factory AdminDocumentFile.fromJson(Map<String, dynamic> json) =>
      _$AdminDocumentFileFromJson(json);

  Map<String, dynamic> toJson() => _$AdminDocumentFileToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
