// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task_page.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$TaskPageCWProxy {
  TaskPage items(List<TaskSummary> items);

  TaskPage page(PageInfo page);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `TaskPage(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// TaskPage(...).copyWith(id: 12, name: "My name")
  /// ````
  TaskPage call({List<TaskSummary> items, PageInfo page});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfTaskPage.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfTaskPage.copyWith.fieldName(...)`
class _$TaskPageCWProxyImpl implements _$TaskPageCWProxy {
  const _$TaskPageCWProxyImpl(this._value);

  final TaskPage _value;

  @override
  TaskPage items(List<TaskSummary> items) => this(items: items);

  @override
  TaskPage page(PageInfo page) => this(page: page);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `TaskPage(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// TaskPage(...).copyWith(id: 12, name: "My name")
  /// ````
  TaskPage call({
    Object? items = const $CopyWithPlaceholder(),
    Object? page = const $CopyWithPlaceholder(),
  }) {
    return TaskPage(
      items: items == const $CopyWithPlaceholder()
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<TaskSummary>,
      page: page == const $CopyWithPlaceholder()
          ? _value.page
          // ignore: cast_nullable_to_non_nullable
          : page as PageInfo,
    );
  }
}

extension $TaskPageCopyWith on TaskPage {
  /// Returns a callable class that can be used as follows: `instanceOfTaskPage.copyWith(...)` or like so:`instanceOfTaskPage.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$TaskPageCWProxy get copyWith => _$TaskPageCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TaskPage _$TaskPageFromJson(Map<String, dynamic> json) =>
    $checkedCreate('TaskPage', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['items', 'page']);
      final val = TaskPage(
        items: $checkedConvert(
          'items',
          (v) => (v as List<dynamic>)
              .map((e) => TaskSummary.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
        page: $checkedConvert(
          'page',
          (v) => PageInfo.fromJson(v as Map<String, dynamic>),
        ),
      );
      return val;
    });

Map<String, dynamic> _$TaskPageToJson(TaskPage instance) => <String, dynamic>{
  'items': instance.items.map((e) => e.toJson()).toList(),
  'page': instance.page.toJson(),
};
