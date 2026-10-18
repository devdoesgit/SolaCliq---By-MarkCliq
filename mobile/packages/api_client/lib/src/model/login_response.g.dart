// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'login_response.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$LoginResponseCWProxy {
  LoginResponse user(Me user);

  LoginResponse tokens(TokenPair? tokens);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `LoginResponse(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// LoginResponse(...).copyWith(id: 12, name: "My name")
  /// ````
  LoginResponse call({Me user, TokenPair? tokens});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfLoginResponse.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfLoginResponse.copyWith.fieldName(...)`
class _$LoginResponseCWProxyImpl implements _$LoginResponseCWProxy {
  const _$LoginResponseCWProxyImpl(this._value);

  final LoginResponse _value;

  @override
  LoginResponse user(Me user) => this(user: user);

  @override
  LoginResponse tokens(TokenPair? tokens) => this(tokens: tokens);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `LoginResponse(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// LoginResponse(...).copyWith(id: 12, name: "My name")
  /// ````
  LoginResponse call({
    Object? user = const $CopyWithPlaceholder(),
    Object? tokens = const $CopyWithPlaceholder(),
  }) {
    return LoginResponse(
      user: user == const $CopyWithPlaceholder()
          ? _value.user
          // ignore: cast_nullable_to_non_nullable
          : user as Me,
      tokens: tokens == const $CopyWithPlaceholder()
          ? _value.tokens
          // ignore: cast_nullable_to_non_nullable
          : tokens as TokenPair?,
    );
  }
}

extension $LoginResponseCopyWith on LoginResponse {
  /// Returns a callable class that can be used as follows: `instanceOfLoginResponse.copyWith(...)` or like so:`instanceOfLoginResponse.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$LoginResponseCWProxy get copyWith => _$LoginResponseCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LoginResponse _$LoginResponseFromJson(Map<String, dynamic> json) =>
    $checkedCreate('LoginResponse', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['user']);
      final val = LoginResponse(
        user: $checkedConvert(
          'user',
          (v) => Me.fromJson(v as Map<String, dynamic>),
        ),
        tokens: $checkedConvert(
          'tokens',
          (v) =>
              v == null ? null : TokenPair.fromJson(v as Map<String, dynamic>),
        ),
      );
      return val;
    });

Map<String, dynamic> _$LoginResponseToJson(LoginResponse instance) =>
    <String, dynamic>{
      'user': instance.user.toJson(),
      'tokens': ?instance.tokens?.toJson(),
    };
