// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'logo_set.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$LogoSetCWProxy {
  LogoSet uploadId(String uploadId);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `LogoSet(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// LogoSet(...).copyWith(id: 12, name: "My name")
  /// ````
  LogoSet call({String uploadId});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfLogoSet.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfLogoSet.copyWith.fieldName(...)`
class _$LogoSetCWProxyImpl implements _$LogoSetCWProxy {
  const _$LogoSetCWProxyImpl(this._value);

  final LogoSet _value;

  @override
  LogoSet uploadId(String uploadId) => this(uploadId: uploadId);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `LogoSet(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// LogoSet(...).copyWith(id: 12, name: "My name")
  /// ````
  LogoSet call({Object? uploadId = const $CopyWithPlaceholder()}) {
    return LogoSet(
      uploadId: uploadId == const $CopyWithPlaceholder()
          ? _value.uploadId
          // ignore: cast_nullable_to_non_nullable
          : uploadId as String,
    );
  }
}

extension $LogoSetCopyWith on LogoSet {
  /// Returns a callable class that can be used as follows: `instanceOfLogoSet.copyWith(...)` or like so:`instanceOfLogoSet.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$LogoSetCWProxy get copyWith => _$LogoSetCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LogoSet _$LogoSetFromJson(Map<String, dynamic> json) =>
    $checkedCreate('LogoSet', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['upload_id']);
      final val = LogoSet(
        uploadId: $checkedConvert('upload_id', (v) => v as String),
      );
      return val;
    }, fieldKeyMap: const {'uploadId': 'upload_id'});

Map<String, dynamic> _$LogoSetToJson(LogoSet instance) => <String, dynamic>{
  'upload_id': instance.uploadId,
};
