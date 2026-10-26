// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$TaskCWProxy {
  Task id(String id);

  Task reference(String reference);

  Task title(String title);

  Task status(TaskStatus status);

  Task dueAt(DateTime dueAt);

  Task stage(TaskStage stage);

  Task assignedBy(Person? assignedBy);

  Task customer(TaskCustomer customer);

  Task adminNote(TaskNote? adminNote);

  Task photos(List<ProofSlot> photos);

  Task checklist(List<ChecklistItem> checklist);

  Task submittedAt(DateTime? submittedAt);

  Task workerNote(String? workerNote);

  Task returned(TaskNote? returned);

  Task problem(TaskProblem? problem);

  Task cancelled(TaskNote? cancelled);

  Task approved(TaskApproved? approved);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `Task(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// Task(...).copyWith(id: 12, name: "My name")
  /// ````
  Task call({
    String id,
    String reference,
    String title,
    TaskStatus status,
    DateTime dueAt,
    TaskStage stage,
    Person? assignedBy,
    TaskCustomer customer,
    TaskNote? adminNote,
    List<ProofSlot> photos,
    List<ChecklistItem> checklist,
    DateTime? submittedAt,
    String? workerNote,
    TaskNote? returned,
    TaskProblem? problem,
    TaskNote? cancelled,
    TaskApproved? approved,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfTask.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfTask.copyWith.fieldName(...)`
class _$TaskCWProxyImpl implements _$TaskCWProxy {
  const _$TaskCWProxyImpl(this._value);

  final Task _value;

  @override
  Task id(String id) => this(id: id);

  @override
  Task reference(String reference) => this(reference: reference);

  @override
  Task title(String title) => this(title: title);

  @override
  Task status(TaskStatus status) => this(status: status);

  @override
  Task dueAt(DateTime dueAt) => this(dueAt: dueAt);

  @override
  Task stage(TaskStage stage) => this(stage: stage);

  @override
  Task assignedBy(Person? assignedBy) => this(assignedBy: assignedBy);

  @override
  Task customer(TaskCustomer customer) => this(customer: customer);

  @override
  Task adminNote(TaskNote? adminNote) => this(adminNote: adminNote);

  @override
  Task photos(List<ProofSlot> photos) => this(photos: photos);

  @override
  Task checklist(List<ChecklistItem> checklist) => this(checklist: checklist);

  @override
  Task submittedAt(DateTime? submittedAt) => this(submittedAt: submittedAt);

  @override
  Task workerNote(String? workerNote) => this(workerNote: workerNote);

  @override
  Task returned(TaskNote? returned) => this(returned: returned);

  @override
  Task problem(TaskProblem? problem) => this(problem: problem);

  @override
  Task cancelled(TaskNote? cancelled) => this(cancelled: cancelled);

  @override
  Task approved(TaskApproved? approved) => this(approved: approved);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `Task(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// Task(...).copyWith(id: 12, name: "My name")
  /// ````
  Task call({
    Object? id = const $CopyWithPlaceholder(),
    Object? reference = const $CopyWithPlaceholder(),
    Object? title = const $CopyWithPlaceholder(),
    Object? status = const $CopyWithPlaceholder(),
    Object? dueAt = const $CopyWithPlaceholder(),
    Object? stage = const $CopyWithPlaceholder(),
    Object? assignedBy = const $CopyWithPlaceholder(),
    Object? customer = const $CopyWithPlaceholder(),
    Object? adminNote = const $CopyWithPlaceholder(),
    Object? photos = const $CopyWithPlaceholder(),
    Object? checklist = const $CopyWithPlaceholder(),
    Object? submittedAt = const $CopyWithPlaceholder(),
    Object? workerNote = const $CopyWithPlaceholder(),
    Object? returned = const $CopyWithPlaceholder(),
    Object? problem = const $CopyWithPlaceholder(),
    Object? cancelled = const $CopyWithPlaceholder(),
    Object? approved = const $CopyWithPlaceholder(),
  }) {
    return Task(
      id: id == const $CopyWithPlaceholder()
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      reference: reference == const $CopyWithPlaceholder()
          ? _value.reference
          // ignore: cast_nullable_to_non_nullable
          : reference as String,
      title: title == const $CopyWithPlaceholder()
          ? _value.title
          // ignore: cast_nullable_to_non_nullable
          : title as String,
      status: status == const $CopyWithPlaceholder()
          ? _value.status
          // ignore: cast_nullable_to_non_nullable
          : status as TaskStatus,
      dueAt: dueAt == const $CopyWithPlaceholder()
          ? _value.dueAt
          // ignore: cast_nullable_to_non_nullable
          : dueAt as DateTime,
      stage: stage == const $CopyWithPlaceholder()
          ? _value.stage
          // ignore: cast_nullable_to_non_nullable
          : stage as TaskStage,
      assignedBy: assignedBy == const $CopyWithPlaceholder()
          ? _value.assignedBy
          // ignore: cast_nullable_to_non_nullable
          : assignedBy as Person?,
      customer: customer == const $CopyWithPlaceholder()
          ? _value.customer
          // ignore: cast_nullable_to_non_nullable
          : customer as TaskCustomer,
      adminNote: adminNote == const $CopyWithPlaceholder()
          ? _value.adminNote
          // ignore: cast_nullable_to_non_nullable
          : adminNote as TaskNote?,
      photos: photos == const $CopyWithPlaceholder()
          ? _value.photos
          // ignore: cast_nullable_to_non_nullable
          : photos as List<ProofSlot>,
      checklist: checklist == const $CopyWithPlaceholder()
          ? _value.checklist
          // ignore: cast_nullable_to_non_nullable
          : checklist as List<ChecklistItem>,
      submittedAt: submittedAt == const $CopyWithPlaceholder()
          ? _value.submittedAt
          // ignore: cast_nullable_to_non_nullable
          : submittedAt as DateTime?,
      workerNote: workerNote == const $CopyWithPlaceholder()
          ? _value.workerNote
          // ignore: cast_nullable_to_non_nullable
          : workerNote as String?,
      returned: returned == const $CopyWithPlaceholder()
          ? _value.returned
          // ignore: cast_nullable_to_non_nullable
          : returned as TaskNote?,
      problem: problem == const $CopyWithPlaceholder()
          ? _value.problem
          // ignore: cast_nullable_to_non_nullable
          : problem as TaskProblem?,
      cancelled: cancelled == const $CopyWithPlaceholder()
          ? _value.cancelled
          // ignore: cast_nullable_to_non_nullable
          : cancelled as TaskNote?,
      approved: approved == const $CopyWithPlaceholder()
          ? _value.approved
          // ignore: cast_nullable_to_non_nullable
          : approved as TaskApproved?,
    );
  }
}

extension $TaskCopyWith on Task {
  /// Returns a callable class that can be used as follows: `instanceOfTask.copyWith(...)` or like so:`instanceOfTask.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$TaskCWProxy get copyWith => _$TaskCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Task _$TaskFromJson(Map<String, dynamic> json) => $checkedCreate(
  'Task',
  json,
  ($checkedConvert) {
    $checkKeys(
      json,
      requiredKeys: const [
        'id',
        'reference',
        'title',
        'status',
        'due_at',
        'stage',
        'customer',
        'photos',
        'checklist',
      ],
    );
    final val = Task(
      id: $checkedConvert('id', (v) => v as String),
      reference: $checkedConvert('reference', (v) => v as String),
      title: $checkedConvert('title', (v) => v as String),
      status: $checkedConvert(
        'status',
        (v) => $enumDecode(_$TaskStatusEnumMap, v),
      ),
      dueAt: $checkedConvert('due_at', (v) => DateTime.parse(v as String)),
      stage: $checkedConvert(
        'stage',
        (v) => TaskStage.fromJson(v as Map<String, dynamic>),
      ),
      assignedBy: $checkedConvert(
        'assigned_by',
        (v) => v == null ? null : Person.fromJson(v as Map<String, dynamic>),
      ),
      customer: $checkedConvert(
        'customer',
        (v) => TaskCustomer.fromJson(v as Map<String, dynamic>),
      ),
      adminNote: $checkedConvert(
        'admin_note',
        (v) => v == null ? null : TaskNote.fromJson(v as Map<String, dynamic>),
      ),
      photos: $checkedConvert(
        'photos',
        (v) => (v as List<dynamic>)
            .map((e) => ProofSlot.fromJson(e as Map<String, dynamic>))
            .toList(),
      ),
      checklist: $checkedConvert(
        'checklist',
        (v) => (v as List<dynamic>)
            .map((e) => ChecklistItem.fromJson(e as Map<String, dynamic>))
            .toList(),
      ),
      submittedAt: $checkedConvert(
        'submitted_at',
        (v) => v == null ? null : DateTime.parse(v as String),
      ),
      workerNote: $checkedConvert('worker_note', (v) => v as String?),
      returned: $checkedConvert(
        'returned',
        (v) => v == null ? null : TaskNote.fromJson(v as Map<String, dynamic>),
      ),
      problem: $checkedConvert(
        'problem',
        (v) =>
            v == null ? null : TaskProblem.fromJson(v as Map<String, dynamic>),
      ),
      cancelled: $checkedConvert(
        'cancelled',
        (v) => v == null ? null : TaskNote.fromJson(v as Map<String, dynamic>),
      ),
      approved: $checkedConvert(
        'approved',
        (v) =>
            v == null ? null : TaskApproved.fromJson(v as Map<String, dynamic>),
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'dueAt': 'due_at',
    'assignedBy': 'assigned_by',
    'adminNote': 'admin_note',
    'submittedAt': 'submitted_at',
    'workerNote': 'worker_note',
  },
);

Map<String, dynamic> _$TaskToJson(Task instance) => <String, dynamic>{
  'id': instance.id,
  'reference': instance.reference,
  'title': instance.title,
  'status': _$TaskStatusEnumMap[instance.status]!,
  'due_at': instance.dueAt.toIso8601String(),
  'stage': instance.stage.toJson(),
  'assigned_by': ?instance.assignedBy?.toJson(),
  'customer': instance.customer.toJson(),
  'admin_note': ?instance.adminNote?.toJson(),
  'photos': instance.photos.map((e) => e.toJson()).toList(),
  'checklist': instance.checklist.map((e) => e.toJson()).toList(),
  'submitted_at': ?instance.submittedAt?.toIso8601String(),
  'worker_note': ?instance.workerNote,
  'returned': ?instance.returned?.toJson(),
  'problem': ?instance.problem?.toJson(),
  'cancelled': ?instance.cancelled?.toJson(),
  'approved': ?instance.approved?.toJson(),
};

const _$TaskStatusEnumMap = {
  TaskStatus.assigned: 'assigned',
  TaskStatus.submitted: 'submitted',
  TaskStatus.returned: 'returned',
  TaskStatus.approved: 'approved',
  TaskStatus.cancelled: 'cancelled',
};
