// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_task_event.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$AdminTaskEventCWProxy {
  AdminTaskEvent kind(AdminTaskEventKindEnum kind);

  AdminTaskEvent actorName(String actorName);

  AdminTaskEvent at(DateTime at);

  AdminTaskEvent detail(String? detail);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `AdminTaskEvent(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// AdminTaskEvent(...).copyWith(id: 12, name: "My name")
  /// ````
  AdminTaskEvent call({
    AdminTaskEventKindEnum kind,
    String actorName,
    DateTime at,
    String? detail,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfAdminTaskEvent.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfAdminTaskEvent.copyWith.fieldName(...)`
class _$AdminTaskEventCWProxyImpl implements _$AdminTaskEventCWProxy {
  const _$AdminTaskEventCWProxyImpl(this._value);

  final AdminTaskEvent _value;

  @override
  AdminTaskEvent kind(AdminTaskEventKindEnum kind) => this(kind: kind);

  @override
  AdminTaskEvent actorName(String actorName) => this(actorName: actorName);

  @override
  AdminTaskEvent at(DateTime at) => this(at: at);

  @override
  AdminTaskEvent detail(String? detail) => this(detail: detail);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `AdminTaskEvent(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// AdminTaskEvent(...).copyWith(id: 12, name: "My name")
  /// ````
  AdminTaskEvent call({
    Object? kind = const $CopyWithPlaceholder(),
    Object? actorName = const $CopyWithPlaceholder(),
    Object? at = const $CopyWithPlaceholder(),
    Object? detail = const $CopyWithPlaceholder(),
  }) {
    return AdminTaskEvent(
      kind: kind == const $CopyWithPlaceholder()
          ? _value.kind
          // ignore: cast_nullable_to_non_nullable
          : kind as AdminTaskEventKindEnum,
      actorName: actorName == const $CopyWithPlaceholder()
          ? _value.actorName
          // ignore: cast_nullable_to_non_nullable
          : actorName as String,
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

extension $AdminTaskEventCopyWith on AdminTaskEvent {
  /// Returns a callable class that can be used as follows: `instanceOfAdminTaskEvent.copyWith(...)` or like so:`instanceOfAdminTaskEvent.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$AdminTaskEventCWProxy get copyWith => _$AdminTaskEventCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AdminTaskEvent _$AdminTaskEventFromJson(Map<String, dynamic> json) =>
    $checkedCreate('AdminTaskEvent', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['kind', 'actor_name', 'at']);
      final val = AdminTaskEvent(
        kind: $checkedConvert(
          'kind',
          (v) => $enumDecode(_$AdminTaskEventKindEnumEnumMap, v),
        ),
        actorName: $checkedConvert('actor_name', (v) => v as String),
        at: $checkedConvert('at', (v) => DateTime.parse(v as String)),
        detail: $checkedConvert('detail', (v) => v as String?),
      );
      return val;
    }, fieldKeyMap: const {'actorName': 'actor_name'});

Map<String, dynamic> _$AdminTaskEventToJson(AdminTaskEvent instance) =>
    <String, dynamic>{
      'kind': _$AdminTaskEventKindEnumEnumMap[instance.kind]!,
      'actor_name': instance.actorName,
      'at': instance.at.toIso8601String(),
      'detail': ?instance.detail,
    };

const _$AdminTaskEventKindEnumEnumMap = {
  AdminTaskEventKindEnum.assigned: 'assigned',
  AdminTaskEventKindEnum.photosUploaded: 'photos_uploaded',
  AdminTaskEventKindEnum.submitted: 'submitted',
  AdminTaskEventKindEnum.resubmitted: 'resubmitted',
  AdminTaskEventKindEnum.returned: 'returned',
  AdminTaskEventKindEnum.approved: 'approved',
  AdminTaskEventKindEnum.problemReported: 'problem_reported',
  AdminTaskEventKindEnum.rescheduled: 'rescheduled',
  AdminTaskEventKindEnum.reassigned: 'reassigned',
  AdminTaskEventKindEnum.cancelled: 'cancelled',
  AdminTaskEventKindEnum.message: 'message',
};
