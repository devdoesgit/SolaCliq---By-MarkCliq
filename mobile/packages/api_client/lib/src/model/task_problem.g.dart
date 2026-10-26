// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task_problem.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$TaskProblemCWProxy {
  TaskProblem reason(TaskProblemReason reason);

  TaskProblem note(String note);

  TaskProblem at(DateTime at);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `TaskProblem(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// TaskProblem(...).copyWith(id: 12, name: "My name")
  /// ````
  TaskProblem call({TaskProblemReason reason, String note, DateTime at});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfTaskProblem.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfTaskProblem.copyWith.fieldName(...)`
class _$TaskProblemCWProxyImpl implements _$TaskProblemCWProxy {
  const _$TaskProblemCWProxyImpl(this._value);

  final TaskProblem _value;

  @override
  TaskProblem reason(TaskProblemReason reason) => this(reason: reason);

  @override
  TaskProblem note(String note) => this(note: note);

  @override
  TaskProblem at(DateTime at) => this(at: at);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `TaskProblem(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// TaskProblem(...).copyWith(id: 12, name: "My name")
  /// ````
  TaskProblem call({
    Object? reason = const $CopyWithPlaceholder(),
    Object? note = const $CopyWithPlaceholder(),
    Object? at = const $CopyWithPlaceholder(),
  }) {
    return TaskProblem(
      reason: reason == const $CopyWithPlaceholder()
          ? _value.reason
          // ignore: cast_nullable_to_non_nullable
          : reason as TaskProblemReason,
      note: note == const $CopyWithPlaceholder()
          ? _value.note
          // ignore: cast_nullable_to_non_nullable
          : note as String,
      at: at == const $CopyWithPlaceholder()
          ? _value.at
          // ignore: cast_nullable_to_non_nullable
          : at as DateTime,
    );
  }
}

extension $TaskProblemCopyWith on TaskProblem {
  /// Returns a callable class that can be used as follows: `instanceOfTaskProblem.copyWith(...)` or like so:`instanceOfTaskProblem.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$TaskProblemCWProxy get copyWith => _$TaskProblemCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TaskProblem _$TaskProblemFromJson(Map<String, dynamic> json) =>
    $checkedCreate('TaskProblem', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['reason', 'note', 'at']);
      final val = TaskProblem(
        reason: $checkedConvert(
          'reason',
          (v) => $enumDecode(_$TaskProblemReasonEnumMap, v),
        ),
        note: $checkedConvert('note', (v) => v as String),
        at: $checkedConvert('at', (v) => DateTime.parse(v as String)),
      );
      return val;
    });

Map<String, dynamic> _$TaskProblemToJson(TaskProblem instance) =>
    <String, dynamic>{
      'reason': _$TaskProblemReasonEnumMap[instance.reason]!,
      'note': instance.note,
      'at': instance.at.toIso8601String(),
    };

const _$TaskProblemReasonEnumMap = {
  TaskProblemReason.customerAway: 'customer_away',
  TaskProblemReason.materialMissing: 'material_missing',
  TaskProblemReason.badWeather: 'bad_weather',
  TaskProblemReason.siteNotReady: 'site_not_ready',
  TaskProblemReason.safety: 'safety',
  TaskProblemReason.other: 'other',
};
