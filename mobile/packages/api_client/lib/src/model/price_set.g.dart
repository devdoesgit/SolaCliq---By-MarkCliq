// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'price_set.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$PriceSetCWProxy {
  PriceSet total(int total);

  PriceSet subsidy(int subsidy);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `PriceSet(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// PriceSet(...).copyWith(id: 12, name: "My name")
  /// ````
  PriceSet call({int total, int subsidy});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfPriceSet.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfPriceSet.copyWith.fieldName(...)`
class _$PriceSetCWProxyImpl implements _$PriceSetCWProxy {
  const _$PriceSetCWProxyImpl(this._value);

  final PriceSet _value;

  @override
  PriceSet total(int total) => this(total: total);

  @override
  PriceSet subsidy(int subsidy) => this(subsidy: subsidy);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `PriceSet(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// PriceSet(...).copyWith(id: 12, name: "My name")
  /// ````
  PriceSet call({
    Object? total = const $CopyWithPlaceholder(),
    Object? subsidy = const $CopyWithPlaceholder(),
  }) {
    return PriceSet(
      total: total == const $CopyWithPlaceholder()
          ? _value.total
          // ignore: cast_nullable_to_non_nullable
          : total as int,
      subsidy: subsidy == const $CopyWithPlaceholder()
          ? _value.subsidy
          // ignore: cast_nullable_to_non_nullable
          : subsidy as int,
    );
  }
}

extension $PriceSetCopyWith on PriceSet {
  /// Returns a callable class that can be used as follows: `instanceOfPriceSet.copyWith(...)` or like so:`instanceOfPriceSet.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$PriceSetCWProxy get copyWith => _$PriceSetCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PriceSet _$PriceSetFromJson(Map<String, dynamic> json) =>
    $checkedCreate('PriceSet', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['total', 'subsidy']);
      final val = PriceSet(
        total: $checkedConvert('total', (v) => (v as num).toInt()),
        subsidy: $checkedConvert('subsidy', (v) => (v as num).toInt()),
      );
      return val;
    });

Map<String, dynamic> _$PriceSetToJson(PriceSet instance) => <String, dynamic>{
  'total': instance.total,
  'subsidy': instance.subsidy,
};
