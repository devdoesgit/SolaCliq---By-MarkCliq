// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'signup_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$SignupRequestCWProxy {
  SignupRequest name(String name);

  SignupRequest email(String email);

  SignupRequest phone(String? phone);

  SignupRequest password(String password);

  SignupRequest termsVersion(int termsVersion);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `SignupRequest(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// SignupRequest(...).copyWith(id: 12, name: "My name")
  /// ````
  SignupRequest call({
    String name,
    String email,
    String? phone,
    String password,
    int termsVersion,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfSignupRequest.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfSignupRequest.copyWith.fieldName(...)`
class _$SignupRequestCWProxyImpl implements _$SignupRequestCWProxy {
  const _$SignupRequestCWProxyImpl(this._value);

  final SignupRequest _value;

  @override
  SignupRequest name(String name) => this(name: name);

  @override
  SignupRequest email(String email) => this(email: email);

  @override
  SignupRequest phone(String? phone) => this(phone: phone);

  @override
  SignupRequest password(String password) => this(password: password);

  @override
  SignupRequest termsVersion(int termsVersion) =>
      this(termsVersion: termsVersion);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `SignupRequest(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// SignupRequest(...).copyWith(id: 12, name: "My name")
  /// ````
  SignupRequest call({
    Object? name = const $CopyWithPlaceholder(),
    Object? email = const $CopyWithPlaceholder(),
    Object? phone = const $CopyWithPlaceholder(),
    Object? password = const $CopyWithPlaceholder(),
    Object? termsVersion = const $CopyWithPlaceholder(),
  }) {
    return SignupRequest(
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
      password: password == const $CopyWithPlaceholder()
          ? _value.password
          // ignore: cast_nullable_to_non_nullable
          : password as String,
      termsVersion: termsVersion == const $CopyWithPlaceholder()
          ? _value.termsVersion
          // ignore: cast_nullable_to_non_nullable
          : termsVersion as int,
    );
  }
}

extension $SignupRequestCopyWith on SignupRequest {
  /// Returns a callable class that can be used as follows: `instanceOfSignupRequest.copyWith(...)` or like so:`instanceOfSignupRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$SignupRequestCWProxy get copyWith => _$SignupRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SignupRequest _$SignupRequestFromJson(Map<String, dynamic> json) =>
    $checkedCreate('SignupRequest', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const ['name', 'email', 'password', 'terms_version'],
      );
      final val = SignupRequest(
        name: $checkedConvert('name', (v) => v as String),
        email: $checkedConvert('email', (v) => v as String),
        phone: $checkedConvert('phone', (v) => v as String?),
        password: $checkedConvert('password', (v) => v as String),
        termsVersion: $checkedConvert(
          'terms_version',
          (v) => (v as num).toInt(),
        ),
      );
      return val;
    }, fieldKeyMap: const {'termsVersion': 'terms_version'});

Map<String, dynamic> _$SignupRequestToJson(SignupRequest instance) =>
    <String, dynamic>{
      'name': instance.name,
      'email': instance.email,
      'phone': ?instance.phone,
      'password': instance.password,
      'terms_version': instance.termsVersion,
    };
