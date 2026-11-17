// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task_create.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$TaskCreateCWProxy {
  TaskCreate adminNote(String? adminNote);

  TaskCreate assigneeId(String assigneeId);

  TaskCreate checklist(List<ChecklistCreate>? checklist);

  TaskCreate customerId(String customerId);

  TaskCreate dueAt(DateTime dueAt);

  TaskCreate photos(List<SlotCreate>? photos);

  TaskCreate stageIndex(int stageIndex);

  TaskCreate title(String title);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `TaskCreate(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// TaskCreate(...).copyWith(id: 12, name: "My name")
  /// ````
  TaskCreate call({
    String? adminNote,
    String assigneeId,
    List<ChecklistCreate>? checklist,
    String customerId,
    DateTime dueAt,
    List<SlotCreate>? photos,
    int stageIndex,
    String title,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfTaskCreate.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfTaskCreate.copyWith.fieldName(...)`
class _$TaskCreateCWProxyImpl implements _$TaskCreateCWProxy {
  const _$TaskCreateCWProxyImpl(this._value);

  final TaskCreate _value;

  @override
  TaskCreate adminNote(String? adminNote) => this(adminNote: adminNote);

  @override
  TaskCreate assigneeId(String assigneeId) => this(assigneeId: assigneeId);

  @override
  TaskCreate checklist(List<ChecklistCreate>? checklist) =>
      this(checklist: checklist);

  @override
  TaskCreate customerId(String customerId) => this(customerId: customerId);

  @override
  TaskCreate dueAt(DateTime dueAt) => this(dueAt: dueAt);

  @override
  TaskCreate photos(List<SlotCreate>? photos) => this(photos: photos);

  @override
  TaskCreate stageIndex(int stageIndex) => this(stageIndex: stageIndex);

  @override
  TaskCreate title(String title) => this(title: title);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `TaskCreate(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// TaskCreate(...).copyWith(id: 12, name: "My name")
  /// ````
  TaskCreate call({
    Object? adminNote = const $CopyWithPlaceholder(),
    Object? assigneeId = const $CopyWithPlaceholder(),
    Object? checklist = const $CopyWithPlaceholder(),
    Object? customerId = const $CopyWithPlaceholder(),
    Object? dueAt = const $CopyWithPlaceholder(),
    Object? photos = const $CopyWithPlaceholder(),
    Object? stageIndex = const $CopyWithPlaceholder(),
    Object? title = const $CopyWithPlaceholder(),
  }) {
    return TaskCreate(
      adminNote: adminNote == const $CopyWithPlaceholder()
          ? _value.adminNote
          // ignore: cast_nullable_to_non_nullable
          : adminNote as String?,
      assigneeId: assigneeId == const $CopyWithPlaceholder()
          ? _value.assigneeId
          // ignore: cast_nullable_to_non_nullable
          : assigneeId as String,
      checklist: checklist == const $CopyWithPlaceholder()
          ? _value.checklist
          // ignore: cast_nullable_to_non_nullable
          : checklist as List<ChecklistCreate>?,
      customerId: customerId == const $CopyWithPlaceholder()
          ? _value.customerId
          // ignore: cast_nullable_to_non_nullable
          : customerId as String,
      dueAt: dueAt == const $CopyWithPlaceholder()
          ? _value.dueAt
          // ignore: cast_nullable_to_non_nullable
          : dueAt as DateTime,
      photos: photos == const $CopyWithPlaceholder()
          ? _value.photos
          // ignore: cast_nullable_to_non_nullable
          : photos as List<SlotCreate>?,
      stageIndex: stageIndex == const $CopyWithPlaceholder()
          ? _value.stageIndex
          // ignore: cast_nullable_to_non_nullable
          : stageIndex as int,
      title: title == const $CopyWithPlaceholder()
          ? _value.title
          // ignore: cast_nullable_to_non_nullable
          : title as String,
    );
  }
}

extension $TaskCreateCopyWith on TaskCreate {
  /// Returns a callable class that can be used as follows: `instanceOfTaskCreate.copyWith(...)` or like so:`instanceOfTaskCreate.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$TaskCreateCWProxy get copyWith => _$TaskCreateCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TaskCreate _$TaskCreateFromJson(Map<String, dynamic> json) => $checkedCreate(
  'TaskCreate',
  json,
  ($checkedConvert) {
    $checkKeys(
      json,
      requiredKeys: const [
        'assignee_id',
        'customer_id',
        'due_at',
        'stage_index',
        'title',
      ],
    );
    final val = TaskCreate(
      adminNote: $checkedConvert('admin_note', (v) => v as String?),
      assigneeId: $checkedConvert('assignee_id', (v) => v as String),
      checklist: $checkedConvert(
        'checklist',
        (v) => (v as List<dynamic>?)
            ?.map((e) => ChecklistCreate.fromJson(e as Map<String, dynamic>))
            .toList(),
      ),
      customerId: $checkedConvert('customer_id', (v) => v as String),
      dueAt: $checkedConvert('due_at', (v) => DateTime.parse(v as String)),
      photos: $checkedConvert(
        'photos',
        (v) => (v as List<dynamic>?)
            ?.map((e) => SlotCreate.fromJson(e as Map<String, dynamic>))
            .toList(),
      ),
      stageIndex: $checkedConvert('stage_index', (v) => (v as num).toInt()),
      title: $checkedConvert('title', (v) => v as String),
    );
    return val;
  },
  fieldKeyMap: const {
    'adminNote': 'admin_note',
    'assigneeId': 'assignee_id',
    'customerId': 'customer_id',
    'dueAt': 'due_at',
    'stageIndex': 'stage_index',
  },
);

Map<String, dynamic> _$TaskCreateToJson(TaskCreate instance) =>
    <String, dynamic>{
      'admin_note': ?instance.adminNote,
      'assignee_id': instance.assigneeId,
      'checklist': ?instance.checklist?.map((e) => e.toJson()).toList(),
      'customer_id': instance.customerId,
      'due_at': instance.dueAt.toIso8601String(),
      'photos': ?instance.photos?.map((e) => e.toJson()).toList(),
      'stage_index': instance.stageIndex,
      'title': instance.title,
    };
