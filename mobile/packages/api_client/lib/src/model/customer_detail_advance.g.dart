// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'customer_detail_advance.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$CustomerDetailAdvanceCWProxy {
  CustomerDetailAdvance status(CustomerDetailAdvanceStatusEnum status);

  CustomerDetailAdvance paidOn(String? paidOn);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `CustomerDetailAdvance(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// CustomerDetailAdvance(...).copyWith(id: 12, name: "My name")
  /// ````
  CustomerDetailAdvance call({
    CustomerDetailAdvanceStatusEnum status,
    String? paidOn,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfCustomerDetailAdvance.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfCustomerDetailAdvance.copyWith.fieldName(...)`
class _$CustomerDetailAdvanceCWProxyImpl
    implements _$CustomerDetailAdvanceCWProxy {
  const _$CustomerDetailAdvanceCWProxyImpl(this._value);

  final CustomerDetailAdvance _value;

  @override
  CustomerDetailAdvance status(CustomerDetailAdvanceStatusEnum status) =>
      this(status: status);

  @override
  CustomerDetailAdvance paidOn(String? paidOn) => this(paidOn: paidOn);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `CustomerDetailAdvance(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// CustomerDetailAdvance(...).copyWith(id: 12, name: "My name")
  /// ````
  CustomerDetailAdvance call({
    Object? status = const $CopyWithPlaceholder(),
    Object? paidOn = const $CopyWithPlaceholder(),
  }) {
    return CustomerDetailAdvance(
      status: status == const $CopyWithPlaceholder()
          ? _value.status
          // ignore: cast_nullable_to_non_nullable
          : status as CustomerDetailAdvanceStatusEnum,
      paidOn: paidOn == const $CopyWithPlaceholder()
          ? _value.paidOn
          // ignore: cast_nullable_to_non_nullable
          : paidOn as String?,
    );
  }
}

extension $CustomerDetailAdvanceCopyWith on CustomerDetailAdvance {
  /// Returns a callable class that can be used as follows: `instanceOfCustomerDetailAdvance.copyWith(...)` or like so:`instanceOfCustomerDetailAdvance.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$CustomerDetailAdvanceCWProxy get copyWith =>
      _$CustomerDetailAdvanceCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CustomerDetailAdvance _$CustomerDetailAdvanceFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('CustomerDetailAdvance', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['status']);
  final val = CustomerDetailAdvance(
    status: $checkedConvert(
      'status',
      (v) => $enumDecode(_$CustomerDetailAdvanceStatusEnumEnumMap, v),
    ),
    paidOn: $checkedConvert('paid_on', (v) => v as String?),
  );
  return val;
}, fieldKeyMap: const {'paidOn': 'paid_on'});

Map<String, dynamic> _$CustomerDetailAdvanceToJson(
  CustomerDetailAdvance instance,
) => <String, dynamic>{
  'status': _$CustomerDetailAdvanceStatusEnumEnumMap[instance.status]!,
  'paid_on': ?instance.paidOn,
};

const _$CustomerDetailAdvanceStatusEnumEnumMap = {
  CustomerDetailAdvanceStatusEnum.due: 'due',
  CustomerDetailAdvanceStatusEnum.paid: 'paid',
};
