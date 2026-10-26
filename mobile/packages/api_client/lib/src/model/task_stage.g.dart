// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task_stage.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$TaskStageCWProxy {
  TaskStage index(int index);

  TaskStage count(int count);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `TaskStage(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// TaskStage(...).copyWith(id: 12, name: "My name")
  /// ````
  TaskStage call({int index, int count});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfTaskStage.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfTaskStage.copyWith.fieldName(...)`
class _$TaskStageCWProxyImpl implements _$TaskStageCWProxy {
  const _$TaskStageCWProxyImpl(this._value);

  final TaskStage _value;

  @override
  TaskStage index(int index) => this(index: index);

  @override
  TaskStage count(int count) => this(count: count);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `TaskStage(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// TaskStage(...).copyWith(id: 12, name: "My name")
  /// ````
  TaskStage call({
    Object? index = const $CopyWithPlaceholder(),
    Object? count = const $CopyWithPlaceholder(),
  }) {
    return TaskStage(
      index: index == const $CopyWithPlaceholder()
          ? _value.index
          // ignore: cast_nullable_to_non_nullable
          : index as int,
      count: count == const $CopyWithPlaceholder()
          ? _value.count
          // ignore: cast_nullable_to_non_nullable
          : count as int,
    );
  }
}

extension $TaskStageCopyWith on TaskStage {
  /// Returns a callable class that can be used as follows: `instanceOfTaskStage.copyWith(...)` or like so:`instanceOfTaskStage.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$TaskStageCWProxy get copyWith => _$TaskStageCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TaskStage _$TaskStageFromJson(Map<String, dynamic> json) =>
    $checkedCreate('TaskStage', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['index', 'count']);
      final val = TaskStage(
        index: $checkedConvert('index', (v) => (v as num).toInt()),
        count: $checkedConvert('count', (v) => (v as num).toInt()),
      );
      return val;
    });

Map<String, dynamic> _$TaskStageToJson(TaskStage instance) => <String, dynamic>{
  'index': instance.index,
  'count': instance.count,
};
