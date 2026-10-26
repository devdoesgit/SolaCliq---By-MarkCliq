// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task_summary.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$TaskSummaryCWProxy {
  TaskSummary id(String id);

  TaskSummary reference(String reference);

  TaskSummary title(String title);

  TaskSummary status(TaskStatus status);

  TaskSummary dueAt(DateTime dueAt);

  TaskSummary customerName(String customerName);

  TaskSummary image(String? image);

  TaskSummary distanceKm(num? distanceKm);

  TaskSummary statusAt(DateTime? statusAt);

  TaskSummary hasProblem(bool? hasProblem);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `TaskSummary(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// TaskSummary(...).copyWith(id: 12, name: "My name")
  /// ````
  TaskSummary call({
    String id,
    String reference,
    String title,
    TaskStatus status,
    DateTime dueAt,
    String customerName,
    String? image,
    num? distanceKm,
    DateTime? statusAt,
    bool? hasProblem,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfTaskSummary.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfTaskSummary.copyWith.fieldName(...)`
class _$TaskSummaryCWProxyImpl implements _$TaskSummaryCWProxy {
  const _$TaskSummaryCWProxyImpl(this._value);

  final TaskSummary _value;

  @override
  TaskSummary id(String id) => this(id: id);

  @override
  TaskSummary reference(String reference) => this(reference: reference);

  @override
  TaskSummary title(String title) => this(title: title);

  @override
  TaskSummary status(TaskStatus status) => this(status: status);

  @override
  TaskSummary dueAt(DateTime dueAt) => this(dueAt: dueAt);

  @override
  TaskSummary customerName(String customerName) =>
      this(customerName: customerName);

  @override
  TaskSummary image(String? image) => this(image: image);

  @override
  TaskSummary distanceKm(num? distanceKm) => this(distanceKm: distanceKm);

  @override
  TaskSummary statusAt(DateTime? statusAt) => this(statusAt: statusAt);

  @override
  TaskSummary hasProblem(bool? hasProblem) => this(hasProblem: hasProblem);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `TaskSummary(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// TaskSummary(...).copyWith(id: 12, name: "My name")
  /// ````
  TaskSummary call({
    Object? id = const $CopyWithPlaceholder(),
    Object? reference = const $CopyWithPlaceholder(),
    Object? title = const $CopyWithPlaceholder(),
    Object? status = const $CopyWithPlaceholder(),
    Object? dueAt = const $CopyWithPlaceholder(),
    Object? customerName = const $CopyWithPlaceholder(),
    Object? image = const $CopyWithPlaceholder(),
    Object? distanceKm = const $CopyWithPlaceholder(),
    Object? statusAt = const $CopyWithPlaceholder(),
    Object? hasProblem = const $CopyWithPlaceholder(),
  }) {
    return TaskSummary(
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
      customerName: customerName == const $CopyWithPlaceholder()
          ? _value.customerName
          // ignore: cast_nullable_to_non_nullable
          : customerName as String,
      image: image == const $CopyWithPlaceholder()
          ? _value.image
          // ignore: cast_nullable_to_non_nullable
          : image as String?,
      distanceKm: distanceKm == const $CopyWithPlaceholder()
          ? _value.distanceKm
          // ignore: cast_nullable_to_non_nullable
          : distanceKm as num?,
      statusAt: statusAt == const $CopyWithPlaceholder()
          ? _value.statusAt
          // ignore: cast_nullable_to_non_nullable
          : statusAt as DateTime?,
      hasProblem: hasProblem == const $CopyWithPlaceholder()
          ? _value.hasProblem
          // ignore: cast_nullable_to_non_nullable
          : hasProblem as bool?,
    );
  }
}

extension $TaskSummaryCopyWith on TaskSummary {
  /// Returns a callable class that can be used as follows: `instanceOfTaskSummary.copyWith(...)` or like so:`instanceOfTaskSummary.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$TaskSummaryCWProxy get copyWith => _$TaskSummaryCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TaskSummary _$TaskSummaryFromJson(Map<String, dynamic> json) => $checkedCreate(
  'TaskSummary',
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
        'customer_name',
      ],
    );
    final val = TaskSummary(
      id: $checkedConvert('id', (v) => v as String),
      reference: $checkedConvert('reference', (v) => v as String),
      title: $checkedConvert('title', (v) => v as String),
      status: $checkedConvert(
        'status',
        (v) => $enumDecode(_$TaskStatusEnumMap, v),
      ),
      dueAt: $checkedConvert('due_at', (v) => DateTime.parse(v as String)),
      customerName: $checkedConvert('customer_name', (v) => v as String),
      image: $checkedConvert('image', (v) => v as String?),
      distanceKm: $checkedConvert('distance_km', (v) => v as num?),
      statusAt: $checkedConvert(
        'status_at',
        (v) => v == null ? null : DateTime.parse(v as String),
      ),
      hasProblem: $checkedConvert('has_problem', (v) => v as bool? ?? false),
    );
    return val;
  },
  fieldKeyMap: const {
    'dueAt': 'due_at',
    'customerName': 'customer_name',
    'distanceKm': 'distance_km',
    'statusAt': 'status_at',
    'hasProblem': 'has_problem',
  },
);

Map<String, dynamic> _$TaskSummaryToJson(TaskSummary instance) =>
    <String, dynamic>{
      'id': instance.id,
      'reference': instance.reference,
      'title': instance.title,
      'status': _$TaskStatusEnumMap[instance.status]!,
      'due_at': instance.dueAt.toIso8601String(),
      'customer_name': instance.customerName,
      'image': ?instance.image,
      'distance_km': ?instance.distanceKm,
      'status_at': ?instance.statusAt?.toIso8601String(),
      'has_problem': ?instance.hasProblem,
    };

const _$TaskStatusEnumMap = {
  TaskStatus.assigned: 'assigned',
  TaskStatus.submitted: 'submitted',
  TaskStatus.returned: 'returned',
  TaskStatus.approved: 'approved',
  TaskStatus.cancelled: 'cancelled',
};
