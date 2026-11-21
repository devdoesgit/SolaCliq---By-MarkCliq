// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'home_attendance.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$HomeAttendanceCWProxy {
  HomeAttendance state(HomeAttendanceStateEnum state);

  HomeAttendance day(AttendanceDay? day);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `HomeAttendance(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// HomeAttendance(...).copyWith(id: 12, name: "My name")
  /// ````
  HomeAttendance call({HomeAttendanceStateEnum state, AttendanceDay? day});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfHomeAttendance.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfHomeAttendance.copyWith.fieldName(...)`
class _$HomeAttendanceCWProxyImpl implements _$HomeAttendanceCWProxy {
  const _$HomeAttendanceCWProxyImpl(this._value);

  final HomeAttendance _value;

  @override
  HomeAttendance state(HomeAttendanceStateEnum state) => this(state: state);

  @override
  HomeAttendance day(AttendanceDay? day) => this(day: day);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `HomeAttendance(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// HomeAttendance(...).copyWith(id: 12, name: "My name")
  /// ````
  HomeAttendance call({
    Object? state = const $CopyWithPlaceholder(),
    Object? day = const $CopyWithPlaceholder(),
  }) {
    return HomeAttendance(
      state: state == const $CopyWithPlaceholder()
          ? _value.state
          // ignore: cast_nullable_to_non_nullable
          : state as HomeAttendanceStateEnum,
      day: day == const $CopyWithPlaceholder()
          ? _value.day
          // ignore: cast_nullable_to_non_nullable
          : day as AttendanceDay?,
    );
  }
}

extension $HomeAttendanceCopyWith on HomeAttendance {
  /// Returns a callable class that can be used as follows: `instanceOfHomeAttendance.copyWith(...)` or like so:`instanceOfHomeAttendance.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$HomeAttendanceCWProxy get copyWith => _$HomeAttendanceCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

HomeAttendance _$HomeAttendanceFromJson(Map<String, dynamic> json) =>
    $checkedCreate('HomeAttendance', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['state']);
      final val = HomeAttendance(
        state: $checkedConvert(
          'state',
          (v) => $enumDecode(_$HomeAttendanceStateEnumEnumMap, v),
        ),
        day: $checkedConvert(
          'day',
          (v) => v == null
              ? null
              : AttendanceDay.fromJson(v as Map<String, dynamic>),
        ),
      );
      return val;
    });

Map<String, dynamic> _$HomeAttendanceToJson(HomeAttendance instance) =>
    <String, dynamic>{
      'state': _$HomeAttendanceStateEnumEnumMap[instance.state]!,
      'day': ?instance.day?.toJson(),
    };

const _$HomeAttendanceStateEnumEnumMap = {
  HomeAttendanceStateEnum.notStarted: 'not_started',
  HomeAttendanceStateEnum.working: 'working',
  HomeAttendanceStateEnum.ended: 'ended',
};
