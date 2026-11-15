// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'device_registration.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$DeviceRegistrationCWProxy {
  DeviceRegistration token(String token);

  DeviceRegistration platform(DeviceRegistrationPlatformEnum platform);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `DeviceRegistration(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// DeviceRegistration(...).copyWith(id: 12, name: "My name")
  /// ````
  DeviceRegistration call({
    String token,
    DeviceRegistrationPlatformEnum platform,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfDeviceRegistration.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfDeviceRegistration.copyWith.fieldName(...)`
class _$DeviceRegistrationCWProxyImpl implements _$DeviceRegistrationCWProxy {
  const _$DeviceRegistrationCWProxyImpl(this._value);

  final DeviceRegistration _value;

  @override
  DeviceRegistration token(String token) => this(token: token);

  @override
  DeviceRegistration platform(DeviceRegistrationPlatformEnum platform) =>
      this(platform: platform);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `DeviceRegistration(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// DeviceRegistration(...).copyWith(id: 12, name: "My name")
  /// ````
  DeviceRegistration call({
    Object? token = const $CopyWithPlaceholder(),
    Object? platform = const $CopyWithPlaceholder(),
  }) {
    return DeviceRegistration(
      token: token == const $CopyWithPlaceholder()
          ? _value.token
          // ignore: cast_nullable_to_non_nullable
          : token as String,
      platform: platform == const $CopyWithPlaceholder()
          ? _value.platform
          // ignore: cast_nullable_to_non_nullable
          : platform as DeviceRegistrationPlatformEnum,
    );
  }
}

extension $DeviceRegistrationCopyWith on DeviceRegistration {
  /// Returns a callable class that can be used as follows: `instanceOfDeviceRegistration.copyWith(...)` or like so:`instanceOfDeviceRegistration.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$DeviceRegistrationCWProxy get copyWith =>
      _$DeviceRegistrationCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DeviceRegistration _$DeviceRegistrationFromJson(Map<String, dynamic> json) =>
    $checkedCreate('DeviceRegistration', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['token', 'platform']);
      final val = DeviceRegistration(
        token: $checkedConvert('token', (v) => v as String),
        platform: $checkedConvert(
          'platform',
          (v) => $enumDecode(_$DeviceRegistrationPlatformEnumEnumMap, v),
        ),
      );
      return val;
    });

Map<String, dynamic> _$DeviceRegistrationToJson(DeviceRegistration instance) =>
    <String, dynamic>{
      'token': instance.token,
      'platform': _$DeviceRegistrationPlatformEnumEnumMap[instance.platform]!,
    };

const _$DeviceRegistrationPlatformEnumEnumMap = {
  DeviceRegistrationPlatformEnum.android: 'android',
};
