// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task_problem_create.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$TaskProblemCreateCWProxy {
  TaskProblemCreate reason(TaskProblemReason reason);

  TaskProblemCreate note(String note);

  TaskProblemCreate uploadId(String? uploadId);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `TaskProblemCreate(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// TaskProblemCreate(...).copyWith(id: 12, name: "My name")
  /// ````
  TaskProblemCreate call({
    TaskProblemReason reason,
    String note,
    String? uploadId,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfTaskProblemCreate.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfTaskProblemCreate.copyWith.fieldName(...)`
class _$TaskProblemCreateCWProxyImpl implements _$TaskProblemCreateCWProxy {
  const _$TaskProblemCreateCWProxyImpl(this._value);

  final TaskProblemCreate _value;

  @override
  TaskProblemCreate reason(TaskProblemReason reason) => this(reason: reason);

  @override
  TaskProblemCreate note(String note) => this(note: note);

  @override
  TaskProblemCreate uploadId(String? uploadId) => this(uploadId: uploadId);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `TaskProblemCreate(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// TaskProblemCreate(...).copyWith(id: 12, name: "My name")
  /// ````
  TaskProblemCreate call({
    Object? reason = const $CopyWithPlaceholder(),
    Object? note = const $CopyWithPlaceholder(),
    Object? uploadId = const $CopyWithPlaceholder(),
  }) {
    return TaskProblemCreate(
      reason: reason == const $CopyWithPlaceholder()
          ? _value.reason
          // ignore: cast_nullable_to_non_nullable
          : reason as TaskProblemReason,
      note: note == const $CopyWithPlaceholder()
          ? _value.note
          // ignore: cast_nullable_to_non_nullable
          : note as String,
      uploadId: uploadId == const $CopyWithPlaceholder()
          ? _value.uploadId
          // ignore: cast_nullable_to_non_nullable
          : uploadId as String?,
    );
  }
}

extension $TaskProblemCreateCopyWith on TaskProblemCreate {
  /// Returns a callable class that can be used as follows: `instanceOfTaskProblemCreate.copyWith(...)` or like so:`instanceOfTaskProblemCreate.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$TaskProblemCreateCWProxy get copyWith =>
      _$TaskProblemCreateCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TaskProblemCreate _$TaskProblemCreateFromJson(Map<String, dynamic> json) =>
    $checkedCreate('TaskProblemCreate', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['reason', 'note']);
      final val = TaskProblemCreate(
        reason: $checkedConvert(
          'reason',
          (v) => $enumDecode(_$TaskProblemReasonEnumMap, v),
        ),
        note: $checkedConvert('note', (v) => v as String),
        uploadId: $checkedConvert('upload_id', (v) => v as String?),
      );
      return val;
    }, fieldKeyMap: const {'uploadId': 'upload_id'});

Map<String, dynamic> _$TaskProblemCreateToJson(TaskProblemCreate instance) =>
    <String, dynamic>{
      'reason': _$TaskProblemReasonEnumMap[instance.reason]!,
      'note': instance.note,
      'upload_id': ?instance.uploadId,
    };

const _$TaskProblemReasonEnumMap = {
  TaskProblemReason.customerAway: 'customer_away',
  TaskProblemReason.materialMissing: 'material_missing',
  TaskProblemReason.badWeather: 'bad_weather',
  TaskProblemReason.siteNotReady: 'site_not_ready',
  TaskProblemReason.safety: 'safety',
  TaskProblemReason.other: 'other',
};
