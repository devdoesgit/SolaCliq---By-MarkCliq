// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'attendance_person.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$AttendancePersonCWProxy {
  AttendancePerson userId(String userId);

  AttendancePerson name(String name);

  AttendancePerson role(Role role);

  AttendancePerson removed(bool removed);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `AttendancePerson(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// AttendancePerson(...).copyWith(id: 12, name: "My name")
  /// ````
  AttendancePerson call({String userId, String name, Role role, bool removed});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfAttendancePerson.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfAttendancePerson.copyWith.fieldName(...)`
class _$AttendancePersonCWProxyImpl implements _$AttendancePersonCWProxy {
  const _$AttendancePersonCWProxyImpl(this._value);

  final AttendancePerson _value;

  @override
  AttendancePerson userId(String userId) => this(userId: userId);

  @override
  AttendancePerson name(String name) => this(name: name);

  @override
  AttendancePerson role(Role role) => this(role: role);

  @override
  AttendancePerson removed(bool removed) => this(removed: removed);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `AttendancePerson(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// AttendancePerson(...).copyWith(id: 12, name: "My name")
  /// ````
  AttendancePerson call({
    Object? userId = const $CopyWithPlaceholder(),
    Object? name = const $CopyWithPlaceholder(),
    Object? role = const $CopyWithPlaceholder(),
    Object? removed = const $CopyWithPlaceholder(),
  }) {
    return AttendancePerson(
      userId: userId == const $CopyWithPlaceholder()
          ? _value.userId
          // ignore: cast_nullable_to_non_nullable
          : userId as String,
      name: name == const $CopyWithPlaceholder()
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String,
      role: role == const $CopyWithPlaceholder()
          ? _value.role
          // ignore: cast_nullable_to_non_nullable
          : role as Role,
      removed: removed == const $CopyWithPlaceholder()
          ? _value.removed
          // ignore: cast_nullable_to_non_nullable
          : removed as bool,
    );
  }
}

extension $AttendancePersonCopyWith on AttendancePerson {
  /// Returns a callable class that can be used as follows: `instanceOfAttendancePerson.copyWith(...)` or like so:`instanceOfAttendancePerson.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$AttendancePersonCWProxy get copyWith => _$AttendancePersonCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AttendancePerson _$AttendancePersonFromJson(Map<String, dynamic> json) =>
    $checkedCreate('AttendancePerson', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const ['user_id', 'name', 'role', 'removed'],
      );
      final val = AttendancePerson(
        userId: $checkedConvert('user_id', (v) => v as String),
        name: $checkedConvert('name', (v) => v as String),
        role: $checkedConvert('role', (v) => $enumDecode(_$RoleEnumMap, v)),
        removed: $checkedConvert('removed', (v) => v as bool),
      );
      return val;
    }, fieldKeyMap: const {'userId': 'user_id'});

Map<String, dynamic> _$AttendancePersonToJson(AttendancePerson instance) =>
    <String, dynamic>{
      'user_id': instance.userId,
      'name': instance.name,
      'role': _$RoleEnumMap[instance.role]!,
      'removed': instance.removed,
    };

const _$RoleEnumMap = {
  Role.orgAdmin: 'org_admin',
  Role.worker: 'worker',
  Role.agent: 'agent',
  Role.customer: 'customer',
};
