// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'customer_registration.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$CustomerRegistrationCWProxy {
  CustomerRegistration id(String id);

  CustomerRegistration reference(String reference);

  CustomerRegistration status(CustomerRegistrationStatusEnum status);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `CustomerRegistration(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// CustomerRegistration(...).copyWith(id: 12, name: "My name")
  /// ````
  CustomerRegistration call({
    String id,
    String reference,
    CustomerRegistrationStatusEnum status,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfCustomerRegistration.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfCustomerRegistration.copyWith.fieldName(...)`
class _$CustomerRegistrationCWProxyImpl
    implements _$CustomerRegistrationCWProxy {
  const _$CustomerRegistrationCWProxyImpl(this._value);

  final CustomerRegistration _value;

  @override
  CustomerRegistration id(String id) => this(id: id);

  @override
  CustomerRegistration reference(String reference) =>
      this(reference: reference);

  @override
  CustomerRegistration status(CustomerRegistrationStatusEnum status) =>
      this(status: status);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `CustomerRegistration(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// CustomerRegistration(...).copyWith(id: 12, name: "My name")
  /// ````
  CustomerRegistration call({
    Object? id = const $CopyWithPlaceholder(),
    Object? reference = const $CopyWithPlaceholder(),
    Object? status = const $CopyWithPlaceholder(),
  }) {
    return CustomerRegistration(
      id: id == const $CopyWithPlaceholder()
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      reference: reference == const $CopyWithPlaceholder()
          ? _value.reference
          // ignore: cast_nullable_to_non_nullable
          : reference as String,
      status: status == const $CopyWithPlaceholder()
          ? _value.status
          // ignore: cast_nullable_to_non_nullable
          : status as CustomerRegistrationStatusEnum,
    );
  }
}

extension $CustomerRegistrationCopyWith on CustomerRegistration {
  /// Returns a callable class that can be used as follows: `instanceOfCustomerRegistration.copyWith(...)` or like so:`instanceOfCustomerRegistration.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$CustomerRegistrationCWProxy get copyWith =>
      _$CustomerRegistrationCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CustomerRegistration _$CustomerRegistrationFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('CustomerRegistration', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['id', 'reference', 'status']);
  final val = CustomerRegistration(
    id: $checkedConvert('id', (v) => v as String),
    reference: $checkedConvert('reference', (v) => v as String),
    status: $checkedConvert(
      'status',
      (v) => $enumDecode(_$CustomerRegistrationStatusEnumEnumMap, v),
    ),
  );
  return val;
});

Map<String, dynamic> _$CustomerRegistrationToJson(
  CustomerRegistration instance,
) => <String, dynamic>{
  'id': instance.id,
  'reference': instance.reference,
  'status': _$CustomerRegistrationStatusEnumEnumMap[instance.status]!,
};

const _$CustomerRegistrationStatusEnumEnumMap = {
  CustomerRegistrationStatusEnum.submitted: 'submitted',
  CustomerRegistrationStatusEnum.verified: 'verified',
  CustomerRegistrationStatusEnum.rejected: 'rejected',
};
