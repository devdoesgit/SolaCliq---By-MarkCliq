// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_task_problem.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$AdminTaskProblemCWProxy {
  AdminTaskProblem reason(TaskProblemReason reason);

  AdminTaskProblem note(String note);

  AdminTaskProblem at(DateTime at);

  AdminTaskProblem photo(AdminFile? photo);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `AdminTaskProblem(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// AdminTaskProblem(...).copyWith(id: 12, name: "My name")
  /// ````
  AdminTaskProblem call({
    TaskProblemReason reason,
    String note,
    DateTime at,
    AdminFile? photo,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfAdminTaskProblem.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfAdminTaskProblem.copyWith.fieldName(...)`
class _$AdminTaskProblemCWProxyImpl implements _$AdminTaskProblemCWProxy {
  const _$AdminTaskProblemCWProxyImpl(this._value);

  final AdminTaskProblem _value;

  @override
  AdminTaskProblem reason(TaskProblemReason reason) => this(reason: reason);

  @override
  AdminTaskProblem note(String note) => this(note: note);

  @override
  AdminTaskProblem at(DateTime at) => this(at: at);

  @override
  AdminTaskProblem photo(AdminFile? photo) => this(photo: photo);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `AdminTaskProblem(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// AdminTaskProblem(...).copyWith(id: 12, name: "My name")
  /// ````
  AdminTaskProblem call({
    Object? reason = const $CopyWithPlaceholder(),
    Object? note = const $CopyWithPlaceholder(),
    Object? at = const $CopyWithPlaceholder(),
    Object? photo = const $CopyWithPlaceholder(),
  }) {
    return AdminTaskProblem(
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
      photo: photo == const $CopyWithPlaceholder()
          ? _value.photo
          // ignore: cast_nullable_to_non_nullable
          : photo as AdminFile?,
    );
  }
}

extension $AdminTaskProblemCopyWith on AdminTaskProblem {
  /// Returns a callable class that can be used as follows: `instanceOfAdminTaskProblem.copyWith(...)` or like so:`instanceOfAdminTaskProblem.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$AdminTaskProblemCWProxy get copyWith => _$AdminTaskProblemCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AdminTaskProblem _$AdminTaskProblemFromJson(Map<String, dynamic> json) =>
    $checkedCreate('AdminTaskProblem', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['reason', 'note', 'at']);
      final val = AdminTaskProblem(
        reason: $checkedConvert(
          'reason',
          (v) => $enumDecode(_$TaskProblemReasonEnumMap, v),
        ),
        note: $checkedConvert('note', (v) => v as String),
        at: $checkedConvert('at', (v) => DateTime.parse(v as String)),
        photo: $checkedConvert(
          'photo',
          (v) =>
              v == null ? null : AdminFile.fromJson(v as Map<String, dynamic>),
        ),
      );
      return val;
    });

Map<String, dynamic> _$AdminTaskProblemToJson(AdminTaskProblem instance) =>
    <String, dynamic>{
      'reason': _$TaskProblemReasonEnumMap[instance.reason]!,
      'note': instance.note,
      'at': instance.at.toIso8601String(),
      'photo': ?instance.photo?.toJson(),
    };

const _$TaskProblemReasonEnumMap = {
  TaskProblemReason.customerAway: 'customer_away',
  TaskProblemReason.materialMissing: 'material_missing',
  TaskProblemReason.badWeather: 'bad_weather',
  TaskProblemReason.siteNotReady: 'site_not_ready',
  TaskProblemReason.safety: 'safety',
  TaskProblemReason.other: 'other',
};
