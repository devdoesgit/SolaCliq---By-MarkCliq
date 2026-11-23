// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_price.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$AdminPriceCWProxy {
  AdminPrice total(int total);

  AdminPrice subsidy(int subsidy);

  AdminPrice editable(bool editable);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `AdminPrice(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// AdminPrice(...).copyWith(id: 12, name: "My name")
  /// ````
  AdminPrice call({int total, int subsidy, bool editable});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfAdminPrice.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfAdminPrice.copyWith.fieldName(...)`
class _$AdminPriceCWProxyImpl implements _$AdminPriceCWProxy {
  const _$AdminPriceCWProxyImpl(this._value);

  final AdminPrice _value;

  @override
  AdminPrice total(int total) => this(total: total);

  @override
  AdminPrice subsidy(int subsidy) => this(subsidy: subsidy);

  @override
  AdminPrice editable(bool editable) => this(editable: editable);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `AdminPrice(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// AdminPrice(...).copyWith(id: 12, name: "My name")
  /// ````
  AdminPrice call({
    Object? total = const $CopyWithPlaceholder(),
    Object? subsidy = const $CopyWithPlaceholder(),
    Object? editable = const $CopyWithPlaceholder(),
  }) {
    return AdminPrice(
      total: total == const $CopyWithPlaceholder()
          ? _value.total
          // ignore: cast_nullable_to_non_nullable
          : total as int,
      subsidy: subsidy == const $CopyWithPlaceholder()
          ? _value.subsidy
          // ignore: cast_nullable_to_non_nullable
          : subsidy as int,
      editable: editable == const $CopyWithPlaceholder()
          ? _value.editable
          // ignore: cast_nullable_to_non_nullable
          : editable as bool,
    );
  }
}

extension $AdminPriceCopyWith on AdminPrice {
  /// Returns a callable class that can be used as follows: `instanceOfAdminPrice.copyWith(...)` or like so:`instanceOfAdminPrice.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$AdminPriceCWProxy get copyWith => _$AdminPriceCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AdminPrice _$AdminPriceFromJson(Map<String, dynamic> json) =>
    $checkedCreate('AdminPrice', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['total', 'subsidy', 'editable']);
      final val = AdminPrice(
        total: $checkedConvert('total', (v) => (v as num).toInt()),
        subsidy: $checkedConvert('subsidy', (v) => (v as num).toInt()),
        editable: $checkedConvert('editable', (v) => v as bool),
      );
      return val;
    });

Map<String, dynamic> _$AdminPriceToJson(AdminPrice instance) =>
    <String, dynamic>{
      'total': instance.total,
      'subsidy': instance.subsidy,
      'editable': instance.editable,
    };
