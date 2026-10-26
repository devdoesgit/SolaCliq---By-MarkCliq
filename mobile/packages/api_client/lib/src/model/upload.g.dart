// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'upload.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$UploadCWProxy {
  Upload uploadId(String uploadId);

  Upload url(String url);

  Upload method(UploadMethodEnum method);

  Upload headers(Map<String, String> headers);

  Upload expiresAt(DateTime expiresAt);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `Upload(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// Upload(...).copyWith(id: 12, name: "My name")
  /// ````
  Upload call({
    String uploadId,
    String url,
    UploadMethodEnum method,
    Map<String, String> headers,
    DateTime expiresAt,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfUpload.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfUpload.copyWith.fieldName(...)`
class _$UploadCWProxyImpl implements _$UploadCWProxy {
  const _$UploadCWProxyImpl(this._value);

  final Upload _value;

  @override
  Upload uploadId(String uploadId) => this(uploadId: uploadId);

  @override
  Upload url(String url) => this(url: url);

  @override
  Upload method(UploadMethodEnum method) => this(method: method);

  @override
  Upload headers(Map<String, String> headers) => this(headers: headers);

  @override
  Upload expiresAt(DateTime expiresAt) => this(expiresAt: expiresAt);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `Upload(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// Upload(...).copyWith(id: 12, name: "My name")
  /// ````
  Upload call({
    Object? uploadId = const $CopyWithPlaceholder(),
    Object? url = const $CopyWithPlaceholder(),
    Object? method = const $CopyWithPlaceholder(),
    Object? headers = const $CopyWithPlaceholder(),
    Object? expiresAt = const $CopyWithPlaceholder(),
  }) {
    return Upload(
      uploadId: uploadId == const $CopyWithPlaceholder()
          ? _value.uploadId
          // ignore: cast_nullable_to_non_nullable
          : uploadId as String,
      url: url == const $CopyWithPlaceholder()
          ? _value.url
          // ignore: cast_nullable_to_non_nullable
          : url as String,
      method: method == const $CopyWithPlaceholder()
          ? _value.method
          // ignore: cast_nullable_to_non_nullable
          : method as UploadMethodEnum,
      headers: headers == const $CopyWithPlaceholder()
          ? _value.headers
          // ignore: cast_nullable_to_non_nullable
          : headers as Map<String, String>,
      expiresAt: expiresAt == const $CopyWithPlaceholder()
          ? _value.expiresAt
          // ignore: cast_nullable_to_non_nullable
          : expiresAt as DateTime,
    );
  }
}

extension $UploadCopyWith on Upload {
  /// Returns a callable class that can be used as follows: `instanceOfUpload.copyWith(...)` or like so:`instanceOfUpload.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$UploadCWProxy get copyWith => _$UploadCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Upload _$UploadFromJson(Map<String, dynamic> json) =>
    $checkedCreate('Upload', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const [
          'upload_id',
          'url',
          'method',
          'headers',
          'expires_at',
        ],
      );
      final val = Upload(
        uploadId: $checkedConvert('upload_id', (v) => v as String),
        url: $checkedConvert('url', (v) => v as String),
        method: $checkedConvert(
          'method',
          (v) => $enumDecode(_$UploadMethodEnumEnumMap, v),
        ),
        headers: $checkedConvert(
          'headers',
          (v) => Map<String, String>.from(v as Map),
        ),
        expiresAt: $checkedConvert(
          'expires_at',
          (v) => DateTime.parse(v as String),
        ),
      );
      return val;
    }, fieldKeyMap: const {'uploadId': 'upload_id', 'expiresAt': 'expires_at'});

Map<String, dynamic> _$UploadToJson(Upload instance) => <String, dynamic>{
  'upload_id': instance.uploadId,
  'url': instance.url,
  'method': _$UploadMethodEnumEnumMap[instance.method]!,
  'headers': instance.headers,
  'expires_at': instance.expiresAt.toIso8601String(),
};

const _$UploadMethodEnumEnumMap = {UploadMethodEnum.PUT: 'PUT'};
