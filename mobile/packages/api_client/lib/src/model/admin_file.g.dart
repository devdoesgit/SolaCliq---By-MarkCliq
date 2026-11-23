// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_file.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$AdminFileCWProxy {
  AdminFile url(String url);

  AdminFile contentType(String contentType);

  AdminFile sizeBytes(int sizeBytes);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `AdminFile(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// AdminFile(...).copyWith(id: 12, name: "My name")
  /// ````
  AdminFile call({String url, String contentType, int sizeBytes});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfAdminFile.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfAdminFile.copyWith.fieldName(...)`
class _$AdminFileCWProxyImpl implements _$AdminFileCWProxy {
  const _$AdminFileCWProxyImpl(this._value);

  final AdminFile _value;

  @override
  AdminFile url(String url) => this(url: url);

  @override
  AdminFile contentType(String contentType) => this(contentType: contentType);

  @override
  AdminFile sizeBytes(int sizeBytes) => this(sizeBytes: sizeBytes);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `AdminFile(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// AdminFile(...).copyWith(id: 12, name: "My name")
  /// ````
  AdminFile call({
    Object? url = const $CopyWithPlaceholder(),
    Object? contentType = const $CopyWithPlaceholder(),
    Object? sizeBytes = const $CopyWithPlaceholder(),
  }) {
    return AdminFile(
      url: url == const $CopyWithPlaceholder()
          ? _value.url
          // ignore: cast_nullable_to_non_nullable
          : url as String,
      contentType: contentType == const $CopyWithPlaceholder()
          ? _value.contentType
          // ignore: cast_nullable_to_non_nullable
          : contentType as String,
      sizeBytes: sizeBytes == const $CopyWithPlaceholder()
          ? _value.sizeBytes
          // ignore: cast_nullable_to_non_nullable
          : sizeBytes as int,
    );
  }
}

extension $AdminFileCopyWith on AdminFile {
  /// Returns a callable class that can be used as follows: `instanceOfAdminFile.copyWith(...)` or like so:`instanceOfAdminFile.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$AdminFileCWProxy get copyWith => _$AdminFileCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AdminFile _$AdminFileFromJson(Map<String, dynamic> json) => $checkedCreate(
  'AdminFile',
  json,
  ($checkedConvert) {
    $checkKeys(json, requiredKeys: const ['url', 'content_type', 'size_bytes']);
    final val = AdminFile(
      url: $checkedConvert('url', (v) => v as String),
      contentType: $checkedConvert('content_type', (v) => v as String),
      sizeBytes: $checkedConvert('size_bytes', (v) => (v as num).toInt()),
    );
    return val;
  },
  fieldKeyMap: const {'contentType': 'content_type', 'sizeBytes': 'size_bytes'},
);

Map<String, dynamic> _$AdminFileToJson(AdminFile instance) => <String, dynamic>{
  'url': instance.url,
  'content_type': instance.contentType,
  'size_bytes': instance.sizeBytes,
};
