// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_task_page.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$AdminTaskPageCWProxy {
  AdminTaskPage items(List<AdminTaskSummary> items);

  AdminTaskPage page(PageInfo page);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `AdminTaskPage(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// AdminTaskPage(...).copyWith(id: 12, name: "My name")
  /// ````
  AdminTaskPage call({List<AdminTaskSummary> items, PageInfo page});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfAdminTaskPage.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfAdminTaskPage.copyWith.fieldName(...)`
class _$AdminTaskPageCWProxyImpl implements _$AdminTaskPageCWProxy {
  const _$AdminTaskPageCWProxyImpl(this._value);

  final AdminTaskPage _value;

  @override
  AdminTaskPage items(List<AdminTaskSummary> items) => this(items: items);

  @override
  AdminTaskPage page(PageInfo page) => this(page: page);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `AdminTaskPage(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// AdminTaskPage(...).copyWith(id: 12, name: "My name")
  /// ````
  AdminTaskPage call({
    Object? items = const $CopyWithPlaceholder(),
    Object? page = const $CopyWithPlaceholder(),
  }) {
    return AdminTaskPage(
      items: items == const $CopyWithPlaceholder()
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<AdminTaskSummary>,
      page: page == const $CopyWithPlaceholder()
          ? _value.page
          // ignore: cast_nullable_to_non_nullable
          : page as PageInfo,
    );
  }
}

extension $AdminTaskPageCopyWith on AdminTaskPage {
  /// Returns a callable class that can be used as follows: `instanceOfAdminTaskPage.copyWith(...)` or like so:`instanceOfAdminTaskPage.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$AdminTaskPageCWProxy get copyWith => _$AdminTaskPageCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AdminTaskPage _$AdminTaskPageFromJson(Map<String, dynamic> json) =>
    $checkedCreate('AdminTaskPage', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['items', 'page']);
      final val = AdminTaskPage(
        items: $checkedConvert(
          'items',
          (v) => (v as List<dynamic>)
              .map((e) => AdminTaskSummary.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
        page: $checkedConvert(
          'page',
          (v) => PageInfo.fromJson(v as Map<String, dynamic>),
        ),
      );
      return val;
    });

Map<String, dynamic> _$AdminTaskPageToJson(AdminTaskPage instance) =>
    <String, dynamic>{
      'items': instance.items.map((e) => e.toJson()).toList(),
      'page': instance.page.toJson(),
    };
