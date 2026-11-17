// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task_return.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$TaskReturnCWProxy {
  TaskReturn note(String note);

  TaskReturn retake(List<String>? retake);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `TaskReturn(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// TaskReturn(...).copyWith(id: 12, name: "My name")
  /// ````
  TaskReturn call({String note, List<String>? retake});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfTaskReturn.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfTaskReturn.copyWith.fieldName(...)`
class _$TaskReturnCWProxyImpl implements _$TaskReturnCWProxy {
  const _$TaskReturnCWProxyImpl(this._value);

  final TaskReturn _value;

  @override
  TaskReturn note(String note) => this(note: note);

  @override
  TaskReturn retake(List<String>? retake) => this(retake: retake);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `TaskReturn(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// TaskReturn(...).copyWith(id: 12, name: "My name")
  /// ````
  TaskReturn call({
    Object? note = const $CopyWithPlaceholder(),
    Object? retake = const $CopyWithPlaceholder(),
  }) {
    return TaskReturn(
      note: note == const $CopyWithPlaceholder()
          ? _value.note
          // ignore: cast_nullable_to_non_nullable
          : note as String,
      retake: retake == const $CopyWithPlaceholder()
          ? _value.retake
          // ignore: cast_nullable_to_non_nullable
          : retake as List<String>?,
    );
  }
}

extension $TaskReturnCopyWith on TaskReturn {
  /// Returns a callable class that can be used as follows: `instanceOfTaskReturn.copyWith(...)` or like so:`instanceOfTaskReturn.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$TaskReturnCWProxy get copyWith => _$TaskReturnCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TaskReturn _$TaskReturnFromJson(Map<String, dynamic> json) =>
    $checkedCreate('TaskReturn', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['note']);
      final val = TaskReturn(
        note: $checkedConvert('note', (v) => v as String),
        retake: $checkedConvert(
          'retake',
          (v) => (v as List<dynamic>?)?.map((e) => e as String).toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$TaskReturnToJson(TaskReturn instance) =>
    <String, dynamic>{'note': instance.note, 'retake': ?instance.retake};
