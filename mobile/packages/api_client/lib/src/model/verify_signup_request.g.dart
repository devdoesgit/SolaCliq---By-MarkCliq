// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'verify_signup_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$VerifySignupRequestCWProxy {
  VerifySignupRequest email(String email);

  VerifySignupRequest code(String code);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `VerifySignupRequest(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// VerifySignupRequest(...).copyWith(id: 12, name: "My name")
  /// ````
  VerifySignupRequest call({String email, String code});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfVerifySignupRequest.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfVerifySignupRequest.copyWith.fieldName(...)`
class _$VerifySignupRequestCWProxyImpl implements _$VerifySignupRequestCWProxy {
  const _$VerifySignupRequestCWProxyImpl(this._value);

  final VerifySignupRequest _value;

  @override
  VerifySignupRequest email(String email) => this(email: email);

  @override
  VerifySignupRequest code(String code) => this(code: code);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `VerifySignupRequest(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// VerifySignupRequest(...).copyWith(id: 12, name: "My name")
  /// ````
  VerifySignupRequest call({
    Object? email = const $CopyWithPlaceholder(),
    Object? code = const $CopyWithPlaceholder(),
  }) {
    return VerifySignupRequest(
      email: email == const $CopyWithPlaceholder()
          ? _value.email
          // ignore: cast_nullable_to_non_nullable
          : email as String,
      code: code == const $CopyWithPlaceholder()
          ? _value.code
          // ignore: cast_nullable_to_non_nullable
          : code as String,
    );
  }
}

extension $VerifySignupRequestCopyWith on VerifySignupRequest {
  /// Returns a callable class that can be used as follows: `instanceOfVerifySignupRequest.copyWith(...)` or like so:`instanceOfVerifySignupRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$VerifySignupRequestCWProxy get copyWith =>
      _$VerifySignupRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

VerifySignupRequest _$VerifySignupRequestFromJson(Map<String, dynamic> json) =>
    $checkedCreate('VerifySignupRequest', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['email', 'code']);
      final val = VerifySignupRequest(
        email: $checkedConvert('email', (v) => v as String),
        code: $checkedConvert('code', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$VerifySignupRequestToJson(
  VerifySignupRequest instance,
) => <String, dynamic>{'email': instance.email, 'code': instance.code};
