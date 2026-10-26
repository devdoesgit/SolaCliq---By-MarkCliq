//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'upload.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class Upload {
  /// Returns a new [Upload] instance.
  Upload({
    required this.uploadId,

    required this.url,

    required this.method,

    required this.headers,

    required this.expiresAt,
  });

  /// UUIDv7.
  @JsonKey(name: r'upload_id', required: true, includeIfNull: false)
  final String uploadId;

  @JsonKey(name: r'url', required: true, includeIfNull: false)
  final String url;

  @JsonKey(name: r'method', required: true, includeIfNull: false)
  final UploadMethodEnum method;

  @JsonKey(name: r'headers', required: true, includeIfNull: false)
  final Map<String, String> headers;

  /// ISO 8601, UTC.
  @JsonKey(name: r'expires_at', required: true, includeIfNull: false)
  final DateTime expiresAt;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is Upload &&
            runtimeType == other.runtimeType &&
            equals(
              [uploadId, url, method, headers, expiresAt],
              [
                other.uploadId,
                other.url,
                other.method,
                other.headers,
                other.expiresAt,
              ],
            );
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^
      mapPropsToHashCode([uploadId, url, method, headers, expiresAt]);

  factory Upload.fromJson(Map<String, dynamic> json) => _$UploadFromJson(json);

  Map<String, dynamic> toJson() => _$UploadToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum UploadMethodEnum {
  @JsonValue(r'PUT')
  PUT(r'PUT');

  const UploadMethodEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
