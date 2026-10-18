// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'login_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$LoginRequestCWProxy {
  LoginRequest email(String email);

  LoginRequest password(String password);

  LoginRequest client(LoginRequestClientEnum client);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `LoginRequest(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// LoginRequest(...).copyWith(id: 12, name: "My name")
  /// ````
  LoginRequest call({
    String email,
    String password,
    LoginRequestClientEnum client,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfLoginRequest.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfLoginRequest.copyWith.fieldName(...)`
class _$LoginRequestCWProxyImpl implements _$LoginRequestCWProxy {
  const _$LoginRequestCWProxyImpl(this._value);

  final LoginRequest _value;

  @override
  LoginRequest email(String email) => this(email: email);

  @override
  LoginRequest password(String password) => this(password: password);

  @override
  LoginRequest client(LoginRequestClientEnum client) => this(client: client);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `LoginRequest(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// LoginRequest(...).copyWith(id: 12, name: "My name")
  /// ````
  LoginRequest call({
    Object? email = const $CopyWithPlaceholder(),
    Object? password = const $CopyWithPlaceholder(),
    Object? client = const $CopyWithPlaceholder(),
  }) {
    return LoginRequest(
      email: email == const $CopyWithPlaceholder()
          ? _value.email
          // ignore: cast_nullable_to_non_nullable
          : email as String,
      password: password == const $CopyWithPlaceholder()
          ? _value.password
          // ignore: cast_nullable_to_non_nullable
          : password as String,
      client: client == const $CopyWithPlaceholder()
          ? _value.client
          // ignore: cast_nullable_to_non_nullable
          : client as LoginRequestClientEnum,
    );
  }
}

extension $LoginRequestCopyWith on LoginRequest {
  /// Returns a callable class that can be used as follows: `instanceOfLoginRequest.copyWith(...)` or like so:`instanceOfLoginRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$LoginRequestCWProxy get copyWith => _$LoginRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LoginRequest _$LoginRequestFromJson(Map<String, dynamic> json) =>
    $checkedCreate('LoginRequest', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['email', 'password', 'client']);
      final val = LoginRequest(
        email: $checkedConvert('email', (v) => v as String),
        password: $checkedConvert('password', (v) => v as String),
        client: $checkedConvert(
          'client',
          (v) => $enumDecode(_$LoginRequestClientEnumEnumMap, v),
        ),
      );
      return val;
    });

Map<String, dynamic> _$LoginRequestToJson(LoginRequest instance) =>
    <String, dynamic>{
      'email': instance.email,
      'password': instance.password,
      'client': _$LoginRequestClientEnumEnumMap[instance.client]!,
    };

const _$LoginRequestClientEnumEnumMap = {
  LoginRequestClientEnum.app: 'app',
  LoginRequestClientEnum.web: 'web',
};
