// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task_event.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$TaskEventCWProxy {
  TaskEvent kind(TaskEventKindEnum kind);

  TaskEvent actor(Person actor);

  TaskEvent at(DateTime at);

  TaskEvent detail(String? detail);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `TaskEvent(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// TaskEvent(...).copyWith(id: 12, name: "My name")
  /// ````
  TaskEvent call({
    TaskEventKindEnum kind,
    Person actor,
    DateTime at,
    String? detail,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfTaskEvent.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfTaskEvent.copyWith.fieldName(...)`
class _$TaskEventCWProxyImpl implements _$TaskEventCWProxy {
  const _$TaskEventCWProxyImpl(this._value);

  final TaskEvent _value;

  @override
  TaskEvent kind(TaskEventKindEnum kind) => this(kind: kind);

  @override
  TaskEvent actor(Person actor) => this(actor: actor);

  @override
  TaskEvent at(DateTime at) => this(at: at);

  @override
  TaskEvent detail(String? detail) => this(detail: detail);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `TaskEvent(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// TaskEvent(...).copyWith(id: 12, name: "My name")
  /// ````
  TaskEvent call({
    Object? kind = const $CopyWithPlaceholder(),
    Object? actor = const $CopyWithPlaceholder(),
    Object? at = const $CopyWithPlaceholder(),
    Object? detail = const $CopyWithPlaceholder(),
  }) {
    return TaskEvent(
      kind: kind == const $CopyWithPlaceholder()
          ? _value.kind
          // ignore: cast_nullable_to_non_nullable
          : kind as TaskEventKindEnum,
      actor: actor == const $CopyWithPlaceholder()
          ? _value.actor
          // ignore: cast_nullable_to_non_nullable
          : actor as Person,
      at: at == const $CopyWithPlaceholder()
          ? _value.at
          // ignore: cast_nullable_to_non_nullable
          : at as DateTime,
      detail: detail == const $CopyWithPlaceholder()
          ? _value.detail
          // ignore: cast_nullable_to_non_nullable
          : detail as String?,
    );
  }
}

extension $TaskEventCopyWith on TaskEvent {
  /// Returns a callable class that can be used as follows: `instanceOfTaskEvent.copyWith(...)` or like so:`instanceOfTaskEvent.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$TaskEventCWProxy get copyWith => _$TaskEventCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TaskEvent _$TaskEventFromJson(Map<String, dynamic> json) =>
    $checkedCreate('TaskEvent', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['kind', 'actor', 'at']);
      final val = TaskEvent(
        kind: $checkedConvert(
          'kind',
          (v) => $enumDecode(_$TaskEventKindEnumEnumMap, v),
        ),
        actor: $checkedConvert(
          'actor',
          (v) => Person.fromJson(v as Map<String, dynamic>),
        ),
        at: $checkedConvert('at', (v) => DateTime.parse(v as String)),
        detail: $checkedConvert('detail', (v) => v as String?),
      );
      return val;
    });

Map<String, dynamic> _$TaskEventToJson(TaskEvent instance) => <String, dynamic>{
  'kind': _$TaskEventKindEnumEnumMap[instance.kind]!,
  'actor': instance.actor.toJson(),
  'at': instance.at.toIso8601String(),
  'detail': ?instance.detail,
};

const _$TaskEventKindEnumEnumMap = {
  TaskEventKindEnum.assigned: 'assigned',
  TaskEventKindEnum.photosUploaded: 'photos_uploaded',
  TaskEventKindEnum.submitted: 'submitted',
  TaskEventKindEnum.resubmitted: 'resubmitted',
  TaskEventKindEnum.returned: 'returned',
  TaskEventKindEnum.approved: 'approved',
  TaskEventKindEnum.problemReported: 'problem_reported',
  TaskEventKindEnum.rescheduled: 'rescheduled',
  TaskEventKindEnum.reassigned: 'reassigned',
  TaskEventKindEnum.cancelled: 'cancelled',
  TaskEventKindEnum.message: 'message',
};
