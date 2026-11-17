// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payment_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$PaymentRequestCWProxy {
  PaymentRequest dueOn(String dueOn);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `PaymentRequest(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// PaymentRequest(...).copyWith(id: 12, name: "My name")
  /// ````
  PaymentRequest call({String dueOn});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfPaymentRequest.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfPaymentRequest.copyWith.fieldName(...)`
class _$PaymentRequestCWProxyImpl implements _$PaymentRequestCWProxy {
  const _$PaymentRequestCWProxyImpl(this._value);

  final PaymentRequest _value;

  @override
  PaymentRequest dueOn(String dueOn) => this(dueOn: dueOn);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `PaymentRequest(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// PaymentRequest(...).copyWith(id: 12, name: "My name")
  /// ````
  PaymentRequest call({Object? dueOn = const $CopyWithPlaceholder()}) {
    return PaymentRequest(
      dueOn: dueOn == const $CopyWithPlaceholder()
          ? _value.dueOn
          // ignore: cast_nullable_to_non_nullable
          : dueOn as String,
    );
  }
}

extension $PaymentRequestCopyWith on PaymentRequest {
  /// Returns a callable class that can be used as follows: `instanceOfPaymentRequest.copyWith(...)` or like so:`instanceOfPaymentRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$PaymentRequestCWProxy get copyWith => _$PaymentRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PaymentRequest _$PaymentRequestFromJson(Map<String, dynamic> json) =>
    $checkedCreate('PaymentRequest', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['due_on']);
      final val = PaymentRequest(
        dueOn: $checkedConvert('due_on', (v) => v as String),
      );
      return val;
    }, fieldKeyMap: const {'dueOn': 'due_on'});

Map<String, dynamic> _$PaymentRequestToJson(PaymentRequest instance) =>
    <String, dynamic>{'due_on': instance.dueOn};
