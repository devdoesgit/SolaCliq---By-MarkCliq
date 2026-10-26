// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task_customer.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$TaskCustomerCWProxy {
  TaskCustomer name(String name);

  TaskCustomer systemKw(num? systemKw);

  TaskCustomer address(String address);

  TaskCustomer phone(String? phone);

  TaskCustomer lat(num? lat);

  TaskCustomer lng(num? lng);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `TaskCustomer(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// TaskCustomer(...).copyWith(id: 12, name: "My name")
  /// ````
  TaskCustomer call({
    String name,
    num? systemKw,
    String address,
    String? phone,
    num? lat,
    num? lng,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfTaskCustomer.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfTaskCustomer.copyWith.fieldName(...)`
class _$TaskCustomerCWProxyImpl implements _$TaskCustomerCWProxy {
  const _$TaskCustomerCWProxyImpl(this._value);

  final TaskCustomer _value;

  @override
  TaskCustomer name(String name) => this(name: name);

  @override
  TaskCustomer systemKw(num? systemKw) => this(systemKw: systemKw);

  @override
  TaskCustomer address(String address) => this(address: address);

  @override
  TaskCustomer phone(String? phone) => this(phone: phone);

  @override
  TaskCustomer lat(num? lat) => this(lat: lat);

  @override
  TaskCustomer lng(num? lng) => this(lng: lng);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `TaskCustomer(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// TaskCustomer(...).copyWith(id: 12, name: "My name")
  /// ````
  TaskCustomer call({
    Object? name = const $CopyWithPlaceholder(),
    Object? systemKw = const $CopyWithPlaceholder(),
    Object? address = const $CopyWithPlaceholder(),
    Object? phone = const $CopyWithPlaceholder(),
    Object? lat = const $CopyWithPlaceholder(),
    Object? lng = const $CopyWithPlaceholder(),
  }) {
    return TaskCustomer(
      name: name == const $CopyWithPlaceholder()
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String,
      systemKw: systemKw == const $CopyWithPlaceholder()
          ? _value.systemKw
          // ignore: cast_nullable_to_non_nullable
          : systemKw as num?,
      address: address == const $CopyWithPlaceholder()
          ? _value.address
          // ignore: cast_nullable_to_non_nullable
          : address as String,
      phone: phone == const $CopyWithPlaceholder()
          ? _value.phone
          // ignore: cast_nullable_to_non_nullable
          : phone as String?,
      lat: lat == const $CopyWithPlaceholder()
          ? _value.lat
          // ignore: cast_nullable_to_non_nullable
          : lat as num?,
      lng: lng == const $CopyWithPlaceholder()
          ? _value.lng
          // ignore: cast_nullable_to_non_nullable
          : lng as num?,
    );
  }
}

extension $TaskCustomerCopyWith on TaskCustomer {
  /// Returns a callable class that can be used as follows: `instanceOfTaskCustomer.copyWith(...)` or like so:`instanceOfTaskCustomer.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$TaskCustomerCWProxy get copyWith => _$TaskCustomerCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TaskCustomer _$TaskCustomerFromJson(Map<String, dynamic> json) =>
    $checkedCreate('TaskCustomer', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['name', 'address']);
      final val = TaskCustomer(
        name: $checkedConvert('name', (v) => v as String),
        systemKw: $checkedConvert('system_kw', (v) => v as num?),
        address: $checkedConvert('address', (v) => v as String),
        phone: $checkedConvert('phone', (v) => v as String?),
        lat: $checkedConvert('lat', (v) => v as num?),
        lng: $checkedConvert('lng', (v) => v as num?),
      );
      return val;
    }, fieldKeyMap: const {'systemKw': 'system_kw'});

Map<String, dynamic> _$TaskCustomerToJson(TaskCustomer instance) =>
    <String, dynamic>{
      'name': instance.name,
      'system_kw': ?instance.systemKw,
      'address': instance.address,
      'phone': ?instance.phone,
      'lat': ?instance.lat,
      'lng': ?instance.lng,
    };
