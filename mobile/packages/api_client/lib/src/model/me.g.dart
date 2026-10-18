// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'me.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$MeCWProxy {
  Me id(String id);

  Me name(String name);

  Me email(String email);

  Me emailVerified(bool emailVerified);

  Me isPlatformAdmin(bool isPlatformAdmin);

  Me memberships(List<Membership> memberships);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `Me(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// Me(...).copyWith(id: 12, name: "My name")
  /// ````
  Me call({
    String id,
    String name,
    String email,
    bool emailVerified,
    bool isPlatformAdmin,
    List<Membership> memberships,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfMe.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfMe.copyWith.fieldName(...)`
class _$MeCWProxyImpl implements _$MeCWProxy {
  const _$MeCWProxyImpl(this._value);

  final Me _value;

  @override
  Me id(String id) => this(id: id);

  @override
  Me name(String name) => this(name: name);

  @override
  Me email(String email) => this(email: email);

  @override
  Me emailVerified(bool emailVerified) => this(emailVerified: emailVerified);

  @override
  Me isPlatformAdmin(bool isPlatformAdmin) =>
      this(isPlatformAdmin: isPlatformAdmin);

  @override
  Me memberships(List<Membership> memberships) =>
      this(memberships: memberships);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `Me(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// Me(...).copyWith(id: 12, name: "My name")
  /// ````
  Me call({
    Object? id = const $CopyWithPlaceholder(),
    Object? name = const $CopyWithPlaceholder(),
    Object? email = const $CopyWithPlaceholder(),
    Object? emailVerified = const $CopyWithPlaceholder(),
    Object? isPlatformAdmin = const $CopyWithPlaceholder(),
    Object? memberships = const $CopyWithPlaceholder(),
  }) {
    return Me(
      id: id == const $CopyWithPlaceholder()
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      name: name == const $CopyWithPlaceholder()
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String,
      email: email == const $CopyWithPlaceholder()
          ? _value.email
          // ignore: cast_nullable_to_non_nullable
          : email as String,
      emailVerified: emailVerified == const $CopyWithPlaceholder()
          ? _value.emailVerified
          // ignore: cast_nullable_to_non_nullable
          : emailVerified as bool,
      isPlatformAdmin: isPlatformAdmin == const $CopyWithPlaceholder()
          ? _value.isPlatformAdmin
          // ignore: cast_nullable_to_non_nullable
          : isPlatformAdmin as bool,
      memberships: memberships == const $CopyWithPlaceholder()
          ? _value.memberships
          // ignore: cast_nullable_to_non_nullable
          : memberships as List<Membership>,
    );
  }
}

extension $MeCopyWith on Me {
  /// Returns a callable class that can be used as follows: `instanceOfMe.copyWith(...)` or like so:`instanceOfMe.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$MeCWProxy get copyWith => _$MeCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Me _$MeFromJson(Map<String, dynamic> json) => $checkedCreate(
  'Me',
  json,
  ($checkedConvert) {
    $checkKeys(
      json,
      requiredKeys: const [
        'id',
        'name',
        'email',
        'email_verified',
        'is_platform_admin',
        'memberships',
      ],
    );
    final val = Me(
      id: $checkedConvert('id', (v) => v as String),
      name: $checkedConvert('name', (v) => v as String),
      email: $checkedConvert('email', (v) => v as String),
      emailVerified: $checkedConvert('email_verified', (v) => v as bool),
      isPlatformAdmin: $checkedConvert('is_platform_admin', (v) => v as bool),
      memberships: $checkedConvert(
        'memberships',
        (v) => (v as List<dynamic>)
            .map((e) => Membership.fromJson(e as Map<String, dynamic>))
            .toList(),
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'emailVerified': 'email_verified',
    'isPlatformAdmin': 'is_platform_admin',
  },
);

Map<String, dynamic> _$MeToJson(Me instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'email': instance.email,
  'email_verified': instance.emailVerified,
  'is_platform_admin': instance.isPlatformAdmin,
  'memberships': instance.memberships.map((e) => e.toJson()).toList(),
};
