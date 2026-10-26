// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'expense_page.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ExpensePageCWProxy {
  ExpensePage items(List<Expense> items);

  ExpensePage page(PageInfo page);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ExpensePage(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ExpensePage(...).copyWith(id: 12, name: "My name")
  /// ````
  ExpensePage call({List<Expense> items, PageInfo page});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfExpensePage.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfExpensePage.copyWith.fieldName(...)`
class _$ExpensePageCWProxyImpl implements _$ExpensePageCWProxy {
  const _$ExpensePageCWProxyImpl(this._value);

  final ExpensePage _value;

  @override
  ExpensePage items(List<Expense> items) => this(items: items);

  @override
  ExpensePage page(PageInfo page) => this(page: page);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ExpensePage(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ExpensePage(...).copyWith(id: 12, name: "My name")
  /// ````
  ExpensePage call({
    Object? items = const $CopyWithPlaceholder(),
    Object? page = const $CopyWithPlaceholder(),
  }) {
    return ExpensePage(
      items: items == const $CopyWithPlaceholder()
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<Expense>,
      page: page == const $CopyWithPlaceholder()
          ? _value.page
          // ignore: cast_nullable_to_non_nullable
          : page as PageInfo,
    );
  }
}

extension $ExpensePageCopyWith on ExpensePage {
  /// Returns a callable class that can be used as follows: `instanceOfExpensePage.copyWith(...)` or like so:`instanceOfExpensePage.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ExpensePageCWProxy get copyWith => _$ExpensePageCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ExpensePage _$ExpensePageFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ExpensePage', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['items', 'page']);
      final val = ExpensePage(
        items: $checkedConvert(
          'items',
          (v) => (v as List<dynamic>)
              .map((e) => Expense.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
        page: $checkedConvert(
          'page',
          (v) => PageInfo.fromJson(v as Map<String, dynamic>),
        ),
      );
      return val;
    });

Map<String, dynamic> _$ExpensePageToJson(ExpensePage instance) =>
    <String, dynamic>{
      'items': instance.items.map((e) => e.toJson()).toList(),
      'page': instance.page.toJson(),
    };
