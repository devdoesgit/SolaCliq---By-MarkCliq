//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api_client/src/model/document_file.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'document_replace.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class DocumentReplace {
  /// Returns a new [DocumentReplace] instance.
  DocumentReplace({required this.files});

  /// Replaces the whole set.
  @JsonKey(name: r'files', required: true, includeIfNull: false)
  final List<DocumentFile> files;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is DocumentReplace &&
            runtimeType == other.runtimeType &&
            equals([files], [other.files]);
  }

  @override
  int get hashCode => runtimeType.hashCode ^ mapPropsToHashCode([files]);

  factory DocumentReplace.fromJson(Map<String, dynamic> json) =>
      _$DocumentReplaceFromJson(json);

  Map<String, dynamic> toJson() => _$DocumentReplaceToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
