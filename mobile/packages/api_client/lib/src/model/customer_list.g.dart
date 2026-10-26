// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'customer_list.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$CustomerListCWProxy {
  CustomerList items(List<CustomerSummary> items);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `CustomerList(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// CustomerList(...).copyWith(id: 12, name: "My name")
  /// ````
  CustomerList call({List<CustomerSummary> items});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfCustomerList.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfCustomerList.copyWith.fieldName(...)`
class _$CustomerListCWProxyImpl implements _$CustomerListCWProxy {
  const _$CustomerListCWProxyImpl(this._value);

  final CustomerList _value;

  @override
  CustomerList items(List<CustomerSummary> items) => this(items: items);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `CustomerList(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// CustomerList(...).copyWith(id: 12, name: "My name")
  /// ````
  CustomerList call({Object? items = const $CopyWithPlaceholder()}) {
    return CustomerList(
      items: items == const $CopyWithPlaceholder()
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<CustomerSummary>,
    );
  }
}

extension $CustomerListCopyWith on CustomerList {
  /// Returns a callable class that can be used as follows: `instanceOfCustomerList.copyWith(...)` or like so:`instanceOfCustomerList.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$CustomerListCWProxy get copyWith => _$CustomerListCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CustomerList _$CustomerListFromJson(Map<String, dynamic> json) =>
    $checkedCreate('CustomerList', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['items']);
      final val = CustomerList(
        items: $checkedConvert(
          'items',
          (v) => (v as List<dynamic>)
              .map((e) => CustomerSummary.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$CustomerListToJson(CustomerList instance) =>
    <String, dynamic>{'items': instance.items.map((e) => e.toJson()).toList()};
