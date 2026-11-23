// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_expense_page.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$AdminExpensePageCWProxy {
  AdminExpensePage items(List<AdminExpenseSummary> items);

  AdminExpensePage page(PageInfo page);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `AdminExpensePage(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// AdminExpensePage(...).copyWith(id: 12, name: "My name")
  /// ````
  AdminExpensePage call({List<AdminExpenseSummary> items, PageInfo page});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfAdminExpensePage.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfAdminExpensePage.copyWith.fieldName(...)`
class _$AdminExpensePageCWProxyImpl implements _$AdminExpensePageCWProxy {
  const _$AdminExpensePageCWProxyImpl(this._value);

  final AdminExpensePage _value;

  @override
  AdminExpensePage items(List<AdminExpenseSummary> items) => this(items: items);

  @override
  AdminExpensePage page(PageInfo page) => this(page: page);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `AdminExpensePage(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// AdminExpensePage(...).copyWith(id: 12, name: "My name")
  /// ````
  AdminExpensePage call({
    Object? items = const $CopyWithPlaceholder(),
    Object? page = const $CopyWithPlaceholder(),
  }) {
    return AdminExpensePage(
      items: items == const $CopyWithPlaceholder()
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<AdminExpenseSummary>,
      page: page == const $CopyWithPlaceholder()
          ? _value.page
          // ignore: cast_nullable_to_non_nullable
          : page as PageInfo,
    );
  }
}

extension $AdminExpensePageCopyWith on AdminExpensePage {
  /// Returns a callable class that can be used as follows: `instanceOfAdminExpensePage.copyWith(...)` or like so:`instanceOfAdminExpensePage.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$AdminExpensePageCWProxy get copyWith => _$AdminExpensePageCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AdminExpensePage _$AdminExpensePageFromJson(Map<String, dynamic> json) =>
    $checkedCreate('AdminExpensePage', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['items', 'page']);
      final val = AdminExpensePage(
        items: $checkedConvert(
          'items',
          (v) => (v as List<dynamic>)
              .map(
                (e) => AdminExpenseSummary.fromJson(e as Map<String, dynamic>),
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

Map<String, dynamic> _$AdminExpensePageToJson(AdminExpensePage instance) =>
    <String, dynamic>{
      'items': instance.items.map((e) => e.toJson()).toList(),
      'page': instance.page.toJson(),
    };
