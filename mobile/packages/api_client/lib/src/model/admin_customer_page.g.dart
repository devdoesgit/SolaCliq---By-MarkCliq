// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_customer_page.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$AdminCustomerPageCWProxy {
  AdminCustomerPage items(List<AdminCustomerSummary> items);

  AdminCustomerPage page(PageInfo page);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `AdminCustomerPage(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// AdminCustomerPage(...).copyWith(id: 12, name: "My name")
  /// ````
  AdminCustomerPage call({List<AdminCustomerSummary> items, PageInfo page});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfAdminCustomerPage.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfAdminCustomerPage.copyWith.fieldName(...)`
class _$AdminCustomerPageCWProxyImpl implements _$AdminCustomerPageCWProxy {
  const _$AdminCustomerPageCWProxyImpl(this._value);

  final AdminCustomerPage _value;

  @override
  AdminCustomerPage items(List<AdminCustomerSummary> items) =>
      this(items: items);

  @override
  AdminCustomerPage page(PageInfo page) => this(page: page);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `AdminCustomerPage(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// AdminCustomerPage(...).copyWith(id: 12, name: "My name")
  /// ````
  AdminCustomerPage call({
    Object? items = const $CopyWithPlaceholder(),
    Object? page = const $CopyWithPlaceholder(),
  }) {
    return AdminCustomerPage(
      items: items == const $CopyWithPlaceholder()
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<AdminCustomerSummary>,
      page: page == const $CopyWithPlaceholder()
          ? _value.page
          // ignore: cast_nullable_to_non_nullable
          : page as PageInfo,
    );
  }
}

extension $AdminCustomerPageCopyWith on AdminCustomerPage {
  /// Returns a callable class that can be used as follows: `instanceOfAdminCustomerPage.copyWith(...)` or like so:`instanceOfAdminCustomerPage.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$AdminCustomerPageCWProxy get copyWith =>
      _$AdminCustomerPageCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AdminCustomerPage _$AdminCustomerPageFromJson(Map<String, dynamic> json) =>
    $checkedCreate('AdminCustomerPage', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['items', 'page']);
      final val = AdminCustomerPage(
        items: $checkedConvert(
          'items',
          (v) => (v as List<dynamic>)
              .map(
                (e) => AdminCustomerSummary.fromJson(e as Map<String, dynamic>),
              )
              .toList(),
        ),
        page: $checkedConvert(
          'page',
          (v) => PageInfo.fromJson(v as Map<String, dynamic>),
        ),
      );
      return val;
    });

Map<String, dynamic> _$AdminCustomerPageToJson(AdminCustomerPage instance) =>
    <String, dynamic>{
      'items': instance.items.map((e) => e.toJson()).toList(),
      'page': instance.page.toJson(),
    };
