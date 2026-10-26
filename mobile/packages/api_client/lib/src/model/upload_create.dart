//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'upload_create.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class UploadCreate {
  /// Returns a new [UploadCreate] instance.
  UploadCreate({
    required this.contentType,

    required this.sizeBytes,

    required this.purpose,
  });

  @JsonKey(name: r'content_type', required: true, includeIfNull: false)
  final UploadCreateContentTypeEnum contentType;

  // minimum: 1
  // maximum: 10485760
  @JsonKey(name: r'size_bytes', required: true, includeIfNull: false)
  final int sizeBytes;

  /// `proof`: a task's photo from the live camera.
  @JsonKey(name: r'purpose', required: true, includeIfNull: false)
  final UploadCreatePurposeEnum purpose;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is UploadCreate &&
            runtimeType == other.runtimeType &&
            equals(
              [contentType, sizeBytes, purpose],
              [other.contentType, other.sizeBytes, other.purpose],
            );
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^
      mapPropsToHashCode([contentType, sizeBytes, purpose]);

  factory UploadCreate.fromJson(Map<String, dynamic> json) =>
      _$UploadCreateFromJson(json);

  Map<String, dynamic> toJson() => _$UploadCreateToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum UploadCreateContentTypeEnum {
  @JsonValue(r'image/jpeg')
  imageSlashJpeg(r'image/jpeg'),
  @JsonValue(r'image/png')
  imageSlashPng(r'image/png'),
  @JsonValue(r'application/pdf')
  applicationSlashPdf(r'application/pdf');

  const UploadCreateContentTypeEnum(this.value);

  final String value;

  @override
  String toString() => value;
}

/// `proof`: a task's photo from the live camera.
enum UploadCreatePurposeEnum {
  @JsonValue(r'receipt')
  receipt(r'receipt'),
  @JsonValue(r'kyc')
  kyc(r'kyc'),
  @JsonValue(r'proof')
  proof(r'proof');

  const UploadCreatePurposeEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
