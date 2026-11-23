//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'admin_file.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AdminFile {
  /// Returns a new [AdminFile] instance.
  AdminFile({
    required this.url,

    required this.contentType,

    required this.sizeBytes,
  });

  /// Works for 15 minutes.
  @JsonKey(name: r'url', required: true, includeIfNull: false)
  final String url;

  /// As the sender declared it; the file may be something else.
  @JsonKey(name: r'content_type', required: true, includeIfNull: false)
  final String contentType;

  @JsonKey(name: r'size_bytes', required: true, includeIfNull: false)
  final int sizeBytes;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is AdminFile &&
            runtimeType == other.runtimeType &&
            equals(
              [url, contentType, sizeBytes],
              [other.url, other.contentType, other.sizeBytes],
            );
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^ mapPropsToHashCode([url, contentType, sizeBytes]);

  factory AdminFile.fromJson(Map<String, dynamic> json) =>
      _$AdminFileFromJson(json);

  Map<String, dynamic> toJson() => _$AdminFileToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
