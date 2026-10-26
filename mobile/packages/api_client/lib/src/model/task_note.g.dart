// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task_note.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$TaskNoteCWProxy {
  TaskNote text(String text);

  TaskNote by(Person by);

  TaskNote at(DateTime at);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `TaskNote(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// TaskNote(...).copyWith(id: 12, name: "My name")
  /// ````
  TaskNote call({String text, Person by, DateTime at});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfTaskNote.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfTaskNote.copyWith.fieldName(...)`
class _$TaskNoteCWProxyImpl implements _$TaskNoteCWProxy {
  const _$TaskNoteCWProxyImpl(this._value);

  final TaskNote _value;

  @override
  TaskNote text(String text) => this(text: text);

  @override
  TaskNote by(Person by) => this(by: by);

  @override
  TaskNote at(DateTime at) => this(at: at);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `TaskNote(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// TaskNote(...).copyWith(id: 12, name: "My name")
  /// ````
  TaskNote call({
    Object? text = const $CopyWithPlaceholder(),
    Object? by = const $CopyWithPlaceholder(),
    Object? at = const $CopyWithPlaceholder(),
  }) {
    return TaskNote(
      text: text == const $CopyWithPlaceholder()
          ? _value.text
          // ignore: cast_nullable_to_non_nullable
          : text as String,
      by: by == const $CopyWithPlaceholder()
          ? _value.by
          // ignore: cast_nullable_to_non_nullable
          : by as Person,
      at: at == const $CopyWithPlaceholder()
          ? _value.at
          // ignore: cast_nullable_to_non_nullable
          : at as DateTime,
    );
  }
}

extension $TaskNoteCopyWith on TaskNote {
  /// Returns a callable class that can be used as follows: `instanceOfTaskNote.copyWith(...)` or like so:`instanceOfTaskNote.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$TaskNoteCWProxy get copyWith => _$TaskNoteCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TaskNote _$TaskNoteFromJson(Map<String, dynamic> json) =>
    $checkedCreate('TaskNote', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['text', 'by', 'at']);
      final val = TaskNote(
        text: $checkedConvert('text', (v) => v as String),
        by: $checkedConvert(
          'by',
          (v) => Person.fromJson(v as Map<String, dynamic>),
        ),
        at: $checkedConvert('at', (v) => DateTime.parse(v as String)),
      );
      return val;
    });

Map<String, dynamic> _$TaskNoteToJson(TaskNote instance) => <String, dynamic>{
  'text': instance.text,
  'by': instance.by.toJson(),
  'at': instance.at.toIso8601String(),
};
