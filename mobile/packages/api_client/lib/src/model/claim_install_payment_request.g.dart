// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'claim_install_payment_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ClaimInstallPaymentRequestCWProxy {
  ClaimInstallPaymentRequest method(
    ClaimInstallPaymentRequestMethodEnum method,
  );

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ClaimInstallPaymentRequest(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ClaimInstallPaymentRequest(...).copyWith(id: 12, name: "My name")
  /// ````
  ClaimInstallPaymentRequest call({
    ClaimInstallPaymentRequestMethodEnum method,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfClaimInstallPaymentRequest.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfClaimInstallPaymentRequest.copyWith.fieldName(...)`
class _$ClaimInstallPaymentRequestCWProxyImpl
    implements _$ClaimInstallPaymentRequestCWProxy {
  const _$ClaimInstallPaymentRequestCWProxyImpl(this._value);

  final ClaimInstallPaymentRequest _value;

  @override
  ClaimInstallPaymentRequest method(
    ClaimInstallPaymentRequestMethodEnum method,
  ) => this(method: method);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ClaimInstallPaymentRequest(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ClaimInstallPaymentRequest(...).copyWith(id: 12, name: "My name")
  /// ````
  ClaimInstallPaymentRequest call({
    Object? method = const $CopyWithPlaceholder(),
  }) {
    return ClaimInstallPaymentRequest(
      method: method == const $CopyWithPlaceholder()
          ? _value.method
          // ignore: cast_nullable_to_non_nullable
          : method as ClaimInstallPaymentRequestMethodEnum,
    );
  }
}

extension $ClaimInstallPaymentRequestCopyWith on ClaimInstallPaymentRequest {
  /// Returns a callable class that can be used as follows: `instanceOfClaimInstallPaymentRequest.copyWith(...)` or like so:`instanceOfClaimInstallPaymentRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ClaimInstallPaymentRequestCWProxy get copyWith =>
      _$ClaimInstallPaymentRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ClaimInstallPaymentRequest _$ClaimInstallPaymentRequestFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('ClaimInstallPaymentRequest', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['method']);
  final val = ClaimInstallPaymentRequest(
    method: $checkedConvert(
      'method',
      (v) => $enumDecode(_$ClaimInstallPaymentRequestMethodEnumEnumMap, v),
    ),
  );
  return val;
});

Map<String, dynamic> _$ClaimInstallPaymentRequestToJson(
  ClaimInstallPaymentRequest instance,
) => <String, dynamic>{
  'method': _$ClaimInstallPaymentRequestMethodEnumEnumMap[instance.method]!,
};

const _$ClaimInstallPaymentRequestMethodEnumEnumMap = {
  ClaimInstallPaymentRequestMethodEnum.upi: 'upi',
  ClaimInstallPaymentRequestMethodEnum.bankTransfer: 'bank_transfer',
};
