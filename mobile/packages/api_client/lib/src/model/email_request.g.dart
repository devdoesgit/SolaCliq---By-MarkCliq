// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'email_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$EmailRequestCWProxy {
  EmailRequest email(String email);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `EmailRequest(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// EmailRequest(...).copyWith(id: 12, name: "My name")
  /// ````
  EmailRequest call({String email});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfEmailRequest.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfEmailRequest.copyWith.fieldName(...)`
class _$EmailRequestCWProxyImpl implements _$EmailRequestCWProxy {
  const _$EmailRequestCWProxyImpl(this._value);

  final EmailRequest _value;

  @override
  EmailRequest email(String email) => this(email: email);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `EmailRequest(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// EmailRequest(...).copyWith(id: 12, name: "My name")
  /// ````
  EmailRequest call({Object? email = const $CopyWithPlaceholder()}) {
    return EmailRequest(
      email: email == const $CopyWithPlaceholder()
          ? _value.email
          // ignore: cast_nullable_to_non_nullable
          : email as String,
    );
  }
}

extension $EmailRequestCopyWith on EmailRequest {
  /// Returns a callable class that can be used as follows: `instanceOfEmailRequest.copyWith(...)` or like so:`instanceOfEmailRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$EmailRequestCWProxy get copyWith => _$EmailRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EmailRequest _$EmailRequestFromJson(Map<String, dynamic> json) =>
    $checkedCreate('EmailRequest', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['email']);
      final val = EmailRequest(
        email: $checkedConvert('email', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$EmailRequestToJson(EmailRequest instance) =>
    <String, dynamic>{'email': instance.email};
