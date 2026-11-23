//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api_client/src/model/document_side.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'document_file.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class DocumentFile {
  /// Returns a new [DocumentFile] instance.
  DocumentFile({required this.uploadId, this.side});

  /// UUIDv7.
  @JsonKey(name: r'upload_id', required: true, includeIfNull: false)
  final String uploadId;

  @JsonKey(name: r'side', required: false, includeIfNull: false)
  final DocumentSide? side;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is DocumentFile &&
            runtimeType == other.runtimeType &&
            equals([uploadId, side], [other.uploadId, other.side]);
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^ mapPropsToHashCode([uploadId, side]);

  factory DocumentFile.fromJson(Map<String, dynamic> json) =>
      _$DocumentFileFromJson(json);

  Map<String, dynamic> toJson() => _$DocumentFileToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
