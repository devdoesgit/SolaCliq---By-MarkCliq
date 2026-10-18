// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'verify_email_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$VerifyEmailRequestCWProxy {
  VerifyEmailRequest email(String email);

  VerifyEmailRequest code(String code);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `VerifyEmailRequest(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// VerifyEmailRequest(...).copyWith(id: 12, name: "My name")
  /// ````
  VerifyEmailRequest call({String email, String code});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfVerifyEmailRequest.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfVerifyEmailRequest.copyWith.fieldName(...)`
class _$VerifyEmailRequestCWProxyImpl implements _$VerifyEmailRequestCWProxy {
  const _$VerifyEmailRequestCWProxyImpl(this._value);

  final VerifyEmailRequest _value;

  @override
  VerifyEmailRequest email(String email) => this(email: email);

  @override
  VerifyEmailRequest code(String code) => this(code: code);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `VerifyEmailRequest(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// VerifyEmailRequest(...).copyWith(id: 12, name: "My name")
  /// ````
  VerifyEmailRequest call({
    Object? email = const $CopyWithPlaceholder(),
    Object? code = const $CopyWithPlaceholder(),
  }) {
    return VerifyEmailRequest(
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

extension $VerifyEmailRequestCopyWith on VerifyEmailRequest {
  /// Returns a callable class that can be used as follows: `instanceOfVerifyEmailRequest.copyWith(...)` or like so:`instanceOfVerifyEmailRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$VerifyEmailRequestCWProxy get copyWith =>
      _$VerifyEmailRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

VerifyEmailRequest _$VerifyEmailRequestFromJson(Map<String, dynamic> json) =>
    $checkedCreate('VerifyEmailRequest', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['email', 'code']);
      final val = VerifyEmailRequest(
        email: $checkedConvert('email', (v) => v as String),
        code: $checkedConvert('code', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$VerifyEmailRequestToJson(VerifyEmailRequest instance) =>
    <String, dynamic>{'email': instance.email, 'code': instance.code};
