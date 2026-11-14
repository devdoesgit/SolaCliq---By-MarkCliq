// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'platform_org_owner.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$PlatformOrgOwnerCWProxy {
  PlatformOrgOwner userId(String userId);

  PlatformOrgOwner name(String name);

  PlatformOrgOwner email(String email);

  PlatformOrgOwner phone(String? phone);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `PlatformOrgOwner(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// PlatformOrgOwner(...).copyWith(id: 12, name: "My name")
  /// ````
  PlatformOrgOwner call({
    String userId,
    String name,
    String email,
    String? phone,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfPlatformOrgOwner.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfPlatformOrgOwner.copyWith.fieldName(...)`
class _$PlatformOrgOwnerCWProxyImpl implements _$PlatformOrgOwnerCWProxy {
  const _$PlatformOrgOwnerCWProxyImpl(this._value);

  final PlatformOrgOwner _value;

  @override
  PlatformOrgOwner userId(String userId) => this(userId: userId);

  @override
  PlatformOrgOwner name(String name) => this(name: name);

  @override
  PlatformOrgOwner email(String email) => this(email: email);

  @override
  PlatformOrgOwner phone(String? phone) => this(phone: phone);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `PlatformOrgOwner(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// PlatformOrgOwner(...).copyWith(id: 12, name: "My name")
  /// ````
  PlatformOrgOwner call({
    Object? userId = const $CopyWithPlaceholder(),
    Object? name = const $CopyWithPlaceholder(),
    Object? email = const $CopyWithPlaceholder(),
    Object? phone = const $CopyWithPlaceholder(),
  }) {
    return PlatformOrgOwner(
      userId: userId == const $CopyWithPlaceholder()
          ? _value.userId
          // ignore: cast_nullable_to_non_nullable
          : userId as String,
      name: name == const $CopyWithPlaceholder()
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String,
      email: email == const $CopyWithPlaceholder()
          ? _value.email
          // ignore: cast_nullable_to_non_nullable
          : email as String,
      phone: phone == const $CopyWithPlaceholder()
          ? _value.phone
          // ignore: cast_nullable_to_non_nullable
          : phone as String?,
    );
  }
}

extension $PlatformOrgOwnerCopyWith on PlatformOrgOwner {
  /// Returns a callable class that can be used as follows: `instanceOfPlatformOrgOwner.copyWith(...)` or like so:`instanceOfPlatformOrgOwner.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$PlatformOrgOwnerCWProxy get copyWith => _$PlatformOrgOwnerCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PlatformOrgOwner _$PlatformOrgOwnerFromJson(Map<String, dynamic> json) =>
    $checkedCreate('PlatformOrgOwner', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['user_id', 'name', 'email']);
      final val = PlatformOrgOwner(
        userId: $checkedConvert('user_id', (v) => v as String),
        name: $checkedConvert('name', (v) => v as String),
        email: $checkedConvert('email', (v) => v as String),
        phone: $checkedConvert('phone', (v) => v as String?),
      );
      return val;
    }, fieldKeyMap: const {'userId': 'user_id'});

Map<String, dynamic> _$PlatformOrgOwnerToJson(PlatformOrgOwner instance) =>
    <String, dynamic>{
      'user_id': instance.userId,
      'name': instance.name,
      'email': instance.email,
      'phone': ?instance.phone,
    };
