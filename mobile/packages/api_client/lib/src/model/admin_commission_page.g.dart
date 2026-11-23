// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_commission_page.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$AdminCommissionPageCWProxy {
  AdminCommissionPage items(List<AdminCommission> items);

  AdminCommissionPage page(PageInfo page);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `AdminCommissionPage(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// AdminCommissionPage(...).copyWith(id: 12, name: "My name")
  /// ````
  AdminCommissionPage call({List<AdminCommission> items, PageInfo page});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfAdminCommissionPage.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfAdminCommissionPage.copyWith.fieldName(...)`
class _$AdminCommissionPageCWProxyImpl implements _$AdminCommissionPageCWProxy {
  const _$AdminCommissionPageCWProxyImpl(this._value);

  final AdminCommissionPage _value;

  @override
  AdminCommissionPage items(List<AdminCommission> items) => this(items: items);

  @override
  AdminCommissionPage page(PageInfo page) => this(page: page);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `AdminCommissionPage(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// AdminCommissionPage(...).copyWith(id: 12, name: "My name")
  /// ````
  AdminCommissionPage call({
    Object? items = const $CopyWithPlaceholder(),
    Object? page = const $CopyWithPlaceholder(),
  }) {
    return AdminCommissionPage(
      items: items == const $CopyWithPlaceholder()
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<AdminCommission>,
      page: page == const $CopyWithPlaceholder()
          ? _value.page
          // ignore: cast_nullable_to_non_nullable
          : page as PageInfo,
    );
  }
}

extension $AdminCommissionPageCopyWith on AdminCommissionPage {
  /// Returns a callable class that can be used as follows: `instanceOfAdminCommissionPage.copyWith(...)` or like so:`instanceOfAdminCommissionPage.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$AdminCommissionPageCWProxy get copyWith =>
      _$AdminCommissionPageCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AdminCommissionPage _$AdminCommissionPageFromJson(Map<String, dynamic> json) =>
    $checkedCreate('AdminCommissionPage', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['items', 'page']);
      final val = AdminCommissionPage(
        items: $checkedConvert(
          'items',
          (v) => (v as List<dynamic>)
              .map((e) => AdminCommission.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
        page: $checkedConvert(
          'page',
          (v) => PageInfo.fromJson(v as Map<String, dynamic>),
        ),
      );
      return val;
    });

Map<String, dynamic> _$AdminCommissionPageToJson(
  AdminCommissionPage instance,
) => <String, dynamic>{
  'items': instance.items.map((e) => e.toJson()).toList(),
  'page': instance.page.toJson(),
};
