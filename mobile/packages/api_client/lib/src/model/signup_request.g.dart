// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'signup_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$SignupRequestCWProxy {
  SignupRequest name(String name);

  SignupRequest email(String email);

  SignupRequest password(String password);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `SignupRequest(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// SignupRequest(...).copyWith(id: 12, name: "My name")
  /// ````
  SignupRequest call({String name, String email, String password});
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
  SignupRequest password(String password) => this(password: password);

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
    Object? password = const $CopyWithPlaceholder(),
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
      password: password == const $CopyWithPlaceholder()
          ? _value.password
          // ignore: cast_nullable_to_non_nullable
          : password as String,
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
      $checkKeys(json, requiredKeys: const ['name', 'email', 'password']);
      final val = SignupRequest(
        name: $checkedConvert('name', (v) => v as String),
        email: $checkedConvert('email', (v) => v as String),
        password: $checkedConvert('password', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$SignupRequestToJson(SignupRequest instance) =>
    <String, dynamic>{
      'name': instance.name,
      'email': instance.email,
      'password': instance.password,
    };
