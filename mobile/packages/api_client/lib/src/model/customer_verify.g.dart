// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'customer_verify.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$CustomerVerifyCWProxy {
  CustomerVerify subsidy(int? subsidy);

  CustomerVerify total(int total);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `CustomerVerify(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// CustomerVerify(...).copyWith(id: 12, name: "My name")
  /// ````
  CustomerVerify call({int? subsidy, int total});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfCustomerVerify.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfCustomerVerify.copyWith.fieldName(...)`
class _$CustomerVerifyCWProxyImpl implements _$CustomerVerifyCWProxy {
  const _$CustomerVerifyCWProxyImpl(this._value);

  final CustomerVerify _value;

  @override
  CustomerVerify subsidy(int? subsidy) => this(subsidy: subsidy);

  @override
  CustomerVerify total(int total) => this(total: total);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `CustomerVerify(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// CustomerVerify(...).copyWith(id: 12, name: "My name")
  /// ````
  CustomerVerify call({
    Object? subsidy = const $CopyWithPlaceholder(),
    Object? total = const $CopyWithPlaceholder(),
  }) {
    return CustomerVerify(
      subsidy: subsidy == const $CopyWithPlaceholder()
          ? _value.subsidy
          // ignore: cast_nullable_to_non_nullable
          : subsidy as int?,
      total: total == const $CopyWithPlaceholder()
          ? _value.total
          // ignore: cast_nullable_to_non_nullable
          : total as int,
    );
  }
}

extension $CustomerVerifyCopyWith on CustomerVerify {
  /// Returns a callable class that can be used as follows: `instanceOfCustomerVerify.copyWith(...)` or like so:`instanceOfCustomerVerify.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$CustomerVerifyCWProxy get copyWith => _$CustomerVerifyCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CustomerVerify _$CustomerVerifyFromJson(Map<String, dynamic> json) =>
    $checkedCreate('CustomerVerify', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['total']);
      final val = CustomerVerify(
        subsidy: $checkedConvert('subsidy', (v) => (v as num?)?.toInt()),
        total: $checkedConvert('total', (v) => (v as num).toInt()),
      );
      return val;
    });

Map<String, dynamic> _$CustomerVerifyToJson(CustomerVerify instance) =>
    <String, dynamic>{'subsidy': ?instance.subsidy, 'total': instance.total};
