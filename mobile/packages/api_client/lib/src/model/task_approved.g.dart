// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task_approved.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$TaskApprovedCWProxy {
  TaskApproved by(Person by);

  TaskApproved at(DateTime at);

  TaskApproved nextTask(TaskSummary? nextTask);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `TaskApproved(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// TaskApproved(...).copyWith(id: 12, name: "My name")
  /// ````
  TaskApproved call({Person by, DateTime at, TaskSummary? nextTask});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfTaskApproved.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfTaskApproved.copyWith.fieldName(...)`
class _$TaskApprovedCWProxyImpl implements _$TaskApprovedCWProxy {
  const _$TaskApprovedCWProxyImpl(this._value);

  final TaskApproved _value;

  @override
  TaskApproved by(Person by) => this(by: by);

  @override
  TaskApproved at(DateTime at) => this(at: at);

  @override
  TaskApproved nextTask(TaskSummary? nextTask) => this(nextTask: nextTask);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `TaskApproved(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// TaskApproved(...).copyWith(id: 12, name: "My name")
  /// ````
  TaskApproved call({
    Object? by = const $CopyWithPlaceholder(),
    Object? at = const $CopyWithPlaceholder(),
    Object? nextTask = const $CopyWithPlaceholder(),
  }) {
    return TaskApproved(
      by: by == const $CopyWithPlaceholder()
          ? _value.by
          // ignore: cast_nullable_to_non_nullable
          : by as Person,
      at: at == const $CopyWithPlaceholder()
          ? _value.at
          // ignore: cast_nullable_to_non_nullable
          : at as DateTime,
      nextTask: nextTask == const $CopyWithPlaceholder()
          ? _value.nextTask
          // ignore: cast_nullable_to_non_nullable
          : nextTask as TaskSummary?,
    );
  }
}

extension $TaskApprovedCopyWith on TaskApproved {
  /// Returns a callable class that can be used as follows: `instanceOfTaskApproved.copyWith(...)` or like so:`instanceOfTaskApproved.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$TaskApprovedCWProxy get copyWith => _$TaskApprovedCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TaskApproved _$TaskApprovedFromJson(Map<String, dynamic> json) =>
    $checkedCreate('TaskApproved', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['by', 'at']);
      final val = TaskApproved(
        by: $checkedConvert(
          'by',
          (v) => Person.fromJson(v as Map<String, dynamic>),
        ),
        at: $checkedConvert('at', (v) => DateTime.parse(v as String)),
        nextTask: $checkedConvert(
          'next_task',
          (v) => v == null
              ? null
              : TaskSummary.fromJson(v as Map<String, dynamic>),
        ),
      );
      return val;
    }, fieldKeyMap: const {'nextTask': 'next_task'});

Map<String, dynamic> _$TaskApprovedToJson(TaskApproved instance) =>
    <String, dynamic>{
      'by': instance.by.toJson(),
      'at': instance.at.toIso8601String(),
      'next_task': ?instance.nextTask?.toJson(),
    };
