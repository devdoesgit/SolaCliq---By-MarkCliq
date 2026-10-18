// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reset_password_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ResetPasswordRequestCWProxy {
  ResetPasswordRequest email(String email);

  ResetPasswordRequest code(String code);

  ResetPasswordRequest newPassword(String newPassword);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ResetPasswordRequest(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ResetPasswordRequest(...).copyWith(id: 12, name: "My name")
  /// ````
  ResetPasswordRequest call({String email, String code, String newPassword});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfResetPasswordRequest.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfResetPasswordRequest.copyWith.fieldName(...)`
class _$ResetPasswordRequestCWProxyImpl
    implements _$ResetPasswordRequestCWProxy {
  const _$ResetPasswordRequestCWProxyImpl(this._value);

  final ResetPasswordRequest _value;

  @override
  ResetPasswordRequest email(String email) => this(email: email);

  @override
  ResetPasswordRequest code(String code) => this(code: code);

  @override
  ResetPasswordRequest newPassword(String newPassword) =>
      this(newPassword: newPassword);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ResetPasswordRequest(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ResetPasswordRequest(...).copyWith(id: 12, name: "My name")
  /// ````
  ResetPasswordRequest call({
    Object? email = const $CopyWithPlaceholder(),
    Object? code = const $CopyWithPlaceholder(),
    Object? newPassword = const $CopyWithPlaceholder(),
  }) {
    return ResetPasswordRequest(
      email: email == const $CopyWithPlaceholder()
          ? _value.email
          // ignore: cast_nullable_to_non_nullable
          : email as String,
      code: code == const $CopyWithPlaceholder()
          ? _value.code
          // ignore: cast_nullable_to_non_nullable
          : code as String,
      newPassword: newPassword == const $CopyWithPlaceholder()
          ? _value.newPassword
          // ignore: cast_nullable_to_non_nullable
          : newPassword as String,
    );
  }
}

extension $ResetPasswordRequestCopyWith on ResetPasswordRequest {
  /// Returns a callable class that can be used as follows: `instanceOfResetPasswordRequest.copyWith(...)` or like so:`instanceOfResetPasswordRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ResetPasswordRequestCWProxy get copyWith =>
      _$ResetPasswordRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ResetPasswordRequest _$ResetPasswordRequestFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('ResetPasswordRequest', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['email', 'code', 'new_password']);
  final val = ResetPasswordRequest(
    email: $checkedConvert('email', (v) => v as String),
    code: $checkedConvert('code', (v) => v as String),
    newPassword: $checkedConvert('new_password', (v) => v as String),
  );
  return val;
}, fieldKeyMap: const {'newPassword': 'new_password'});

Map<String, dynamic> _$ResetPasswordRequestToJson(
  ResetPasswordRequest instance,
) => <String, dynamic>{
  'email': instance.email,
  'code': instance.code,
  'new_password': instance.newPassword,
};
