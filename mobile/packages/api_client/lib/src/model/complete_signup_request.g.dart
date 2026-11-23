// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'complete_signup_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$CompleteSignupRequestCWProxy {
  CompleteSignupRequest signupToken(String signupToken);

  CompleteSignupRequest name(String name);

  CompleteSignupRequest phone(String? phone);

  CompleteSignupRequest password(String password);

  CompleteSignupRequest termsVersion(int termsVersion);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `CompleteSignupRequest(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// CompleteSignupRequest(...).copyWith(id: 12, name: "My name")
  /// ````
  CompleteSignupRequest call({
    String signupToken,
    String name,
    String? phone,
    String password,
    int termsVersion,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfCompleteSignupRequest.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfCompleteSignupRequest.copyWith.fieldName(...)`
class _$CompleteSignupRequestCWProxyImpl
    implements _$CompleteSignupRequestCWProxy {
  const _$CompleteSignupRequestCWProxyImpl(this._value);

  final CompleteSignupRequest _value;

  @override
  CompleteSignupRequest signupToken(String signupToken) =>
      this(signupToken: signupToken);

  @override
  CompleteSignupRequest name(String name) => this(name: name);

  @override
  CompleteSignupRequest phone(String? phone) => this(phone: phone);

  @override
  CompleteSignupRequest password(String password) => this(password: password);

  @override
  CompleteSignupRequest termsVersion(int termsVersion) =>
      this(termsVersion: termsVersion);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `CompleteSignupRequest(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// CompleteSignupRequest(...).copyWith(id: 12, name: "My name")
  /// ````
  CompleteSignupRequest call({
    Object? signupToken = const $CopyWithPlaceholder(),
    Object? name = const $CopyWithPlaceholder(),
    Object? phone = const $CopyWithPlaceholder(),
    Object? password = const $CopyWithPlaceholder(),
    Object? termsVersion = const $CopyWithPlaceholder(),
  }) {
    return CompleteSignupRequest(
      signupToken: signupToken == const $CopyWithPlaceholder()
          ? _value.signupToken
          // ignore: cast_nullable_to_non_nullable
          : signupToken as String,
      name: name == const $CopyWithPlaceholder()
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String,
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

extension $CompleteSignupRequestCopyWith on CompleteSignupRequest {
  /// Returns a callable class that can be used as follows: `instanceOfCompleteSignupRequest.copyWith(...)` or like so:`instanceOfCompleteSignupRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$CompleteSignupRequestCWProxy get copyWith =>
      _$CompleteSignupRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CompleteSignupRequest _$CompleteSignupRequestFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'CompleteSignupRequest',
  json,
  ($checkedConvert) {
    $checkKeys(
      json,
      requiredKeys: const ['signup_token', 'name', 'password', 'terms_version'],
    );
    final val = CompleteSignupRequest(
      signupToken: $checkedConvert('signup_token', (v) => v as String),
      name: $checkedConvert('name', (v) => v as String),
      phone: $checkedConvert('phone', (v) => v as String?),
      password: $checkedConvert('password', (v) => v as String),
      termsVersion: $checkedConvert('terms_version', (v) => (v as num).toInt()),
    );
    return val;
  },
  fieldKeyMap: const {
    'signupToken': 'signup_token',
    'termsVersion': 'terms_version',
  },
);

Map<String, dynamic> _$CompleteSignupRequestToJson(
  CompleteSignupRequest instance,
) => <String, dynamic>{
  'signup_token': instance.signupToken,
  'name': instance.name,
  'phone': ?instance.phone,
  'password': instance.password,
  'terms_version': instance.termsVersion,
};
