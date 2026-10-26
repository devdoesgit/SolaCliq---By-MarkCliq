// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task_history.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$TaskHistoryCWProxy {
  TaskHistory events(List<TaskEvent> events);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `TaskHistory(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// TaskHistory(...).copyWith(id: 12, name: "My name")
  /// ````
  TaskHistory call({List<TaskEvent> events});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfTaskHistory.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfTaskHistory.copyWith.fieldName(...)`
class _$TaskHistoryCWProxyImpl implements _$TaskHistoryCWProxy {
  const _$TaskHistoryCWProxyImpl(this._value);

  final TaskHistory _value;

  @override
  TaskHistory events(List<TaskEvent> events) => this(events: events);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `TaskHistory(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// TaskHistory(...).copyWith(id: 12, name: "My name")
  /// ````
  TaskHistory call({Object? events = const $CopyWithPlaceholder()}) {
    return TaskHistory(
      events: events == const $CopyWithPlaceholder()
          ? _value.events
          // ignore: cast_nullable_to_non_nullable
          : events as List<TaskEvent>,
    );
  }
}

extension $TaskHistoryCopyWith on TaskHistory {
  /// Returns a callable class that can be used as follows: `instanceOfTaskHistory.copyWith(...)` or like so:`instanceOfTaskHistory.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$TaskHistoryCWProxy get copyWith => _$TaskHistoryCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TaskHistory _$TaskHistoryFromJson(Map<String, dynamic> json) =>
    $checkedCreate('TaskHistory', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['events']);
      final val = TaskHistory(
        events: $checkedConvert(
          'events',
          (v) => (v as List<dynamic>)
              .map((e) => TaskEvent.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$TaskHistoryToJson(TaskHistory instance) =>
    <String, dynamic>{
      'events': instance.events.map((e) => e.toJson()).toList(),
    };
