// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task_schedule.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$TaskScheduleCWProxy {
  TaskSchedule assigneeId(String? assigneeId);

  TaskSchedule dueAt(DateTime dueAt);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `TaskSchedule(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// TaskSchedule(...).copyWith(id: 12, name: "My name")
  /// ````
  TaskSchedule call({String? assigneeId, DateTime dueAt});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfTaskSchedule.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfTaskSchedule.copyWith.fieldName(...)`
class _$TaskScheduleCWProxyImpl implements _$TaskScheduleCWProxy {
  const _$TaskScheduleCWProxyImpl(this._value);

  final TaskSchedule _value;

  @override
  TaskSchedule assigneeId(String? assigneeId) => this(assigneeId: assigneeId);

  @override
  TaskSchedule dueAt(DateTime dueAt) => this(dueAt: dueAt);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `TaskSchedule(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// TaskSchedule(...).copyWith(id: 12, name: "My name")
  /// ````
  TaskSchedule call({
    Object? assigneeId = const $CopyWithPlaceholder(),
    Object? dueAt = const $CopyWithPlaceholder(),
  }) {
    return TaskSchedule(
      assigneeId: assigneeId == const $CopyWithPlaceholder()
          ? _value.assigneeId
          // ignore: cast_nullable_to_non_nullable
          : assigneeId as String?,
      dueAt: dueAt == const $CopyWithPlaceholder()
          ? _value.dueAt
          // ignore: cast_nullable_to_non_nullable
          : dueAt as DateTime,
    );
  }
}

extension $TaskScheduleCopyWith on TaskSchedule {
  /// Returns a callable class that can be used as follows: `instanceOfTaskSchedule.copyWith(...)` or like so:`instanceOfTaskSchedule.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$TaskScheduleCWProxy get copyWith => _$TaskScheduleCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TaskSchedule _$TaskScheduleFromJson(Map<String, dynamic> json) =>
    $checkedCreate('TaskSchedule', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['due_at']);
      final val = TaskSchedule(
        assigneeId: $checkedConvert('assignee_id', (v) => v as String?),
        dueAt: $checkedConvert('due_at', (v) => DateTime.parse(v as String)),
      );
      return val;
    }, fieldKeyMap: const {'assigneeId': 'assignee_id', 'dueAt': 'due_at'});

Map<String, dynamic> _$TaskScheduleToJson(TaskSchedule instance) =>
    <String, dynamic>{
      'assignee_id': ?instance.assigneeId,
      'due_at': instance.dueAt.toIso8601String(),
    };
