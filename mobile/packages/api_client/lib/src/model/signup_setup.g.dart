// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'signup_setup.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$SignupSetupCWProxy {
  SignupSetup signupToken(String signupToken);

  SignupSetup expiresIn(int expiresIn);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `SignupSetup(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// SignupSetup(...).copyWith(id: 12, name: "My name")
  /// ````
  SignupSetup call({String signupToken, int expiresIn});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfSignupSetup.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfSignupSetup.copyWith.fieldName(...)`
class _$SignupSetupCWProxyImpl implements _$SignupSetupCWProxy {
  const _$SignupSetupCWProxyImpl(this._value);

  final SignupSetup _value;

  @override
  SignupSetup signupToken(String signupToken) => this(signupToken: signupToken);

  @override
  SignupSetup expiresIn(int expiresIn) => this(expiresIn: expiresIn);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `SignupSetup(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// SignupSetup(...).copyWith(id: 12, name: "My name")
  /// ````
  SignupSetup call({
    Object? signupToken = const $CopyWithPlaceholder(),
    Object? expiresIn = const $CopyWithPlaceholder(),
  }) {
    return SignupSetup(
      signupToken: signupToken == const $CopyWithPlaceholder()
          ? _value.signupToken
          // ignore: cast_nullable_to_non_nullable
          : signupToken as String,
      expiresIn: expiresIn == const $CopyWithPlaceholder()
          ? _value.expiresIn
          // ignore: cast_nullable_to_non_nullable
          : expiresIn as int,
    );
  }
}

extension $SignupSetupCopyWith on SignupSetup {
  /// Returns a callable class that can be used as follows: `instanceOfSignupSetup.copyWith(...)` or like so:`instanceOfSignupSetup.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$SignupSetupCWProxy get copyWith => _$SignupSetupCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SignupSetup _$SignupSetupFromJson(Map<String, dynamic> json) => $checkedCreate(
  'SignupSetup',
  json,
  ($checkedConvert) {
    $checkKeys(json, requiredKeys: const ['signup_token', 'expires_in']);
    final val = SignupSetup(
      signupToken: $checkedConvert('signup_token', (v) => v as String),
      expiresIn: $checkedConvert('expires_in', (v) => (v as num).toInt()),
    );
    return val;
  },
  fieldKeyMap: const {'signupToken': 'signup_token', 'expiresIn': 'expires_in'},
);

Map<String, dynamic> _$SignupSetupToJson(SignupSetup instance) =>
    <String, dynamic>{
      'signup_token': instance.signupToken,
      'expires_in': instance.expiresIn,
    };
