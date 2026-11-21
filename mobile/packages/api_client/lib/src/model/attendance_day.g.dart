// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'attendance_day.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$AttendanceDayCWProxy {
  AttendanceDay date(String date);

  AttendanceDay status(AttendanceStatus status);

  AttendanceDay start(AttendanceTap start);

  AttendanceDay end(AttendanceTap? end);

  AttendanceDay minutes(int? minutes);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `AttendanceDay(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// AttendanceDay(...).copyWith(id: 12, name: "My name")
  /// ````
  AttendanceDay call({
    String date,
    AttendanceStatus status,
    AttendanceTap start,
    AttendanceTap? end,
    int? minutes,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfAttendanceDay.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfAttendanceDay.copyWith.fieldName(...)`
class _$AttendanceDayCWProxyImpl implements _$AttendanceDayCWProxy {
  const _$AttendanceDayCWProxyImpl(this._value);

  final AttendanceDay _value;

  @override
  AttendanceDay date(String date) => this(date: date);

  @override
  AttendanceDay status(AttendanceStatus status) => this(status: status);

  @override
  AttendanceDay start(AttendanceTap start) => this(start: start);

  @override
  AttendanceDay end(AttendanceTap? end) => this(end: end);

  @override
  AttendanceDay minutes(int? minutes) => this(minutes: minutes);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `AttendanceDay(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// AttendanceDay(...).copyWith(id: 12, name: "My name")
  /// ````
  AttendanceDay call({
    Object? date = const $CopyWithPlaceholder(),
    Object? status = const $CopyWithPlaceholder(),
    Object? start = const $CopyWithPlaceholder(),
    Object? end = const $CopyWithPlaceholder(),
    Object? minutes = const $CopyWithPlaceholder(),
  }) {
    return AttendanceDay(
      date: date == const $CopyWithPlaceholder()
          ? _value.date
          // ignore: cast_nullable_to_non_nullable
          : date as String,
      status: status == const $CopyWithPlaceholder()
          ? _value.status
          // ignore: cast_nullable_to_non_nullable
          : status as AttendanceStatus,
      start: start == const $CopyWithPlaceholder()
          ? _value.start
          // ignore: cast_nullable_to_non_nullable
          : start as AttendanceTap,
      end: end == const $CopyWithPlaceholder()
          ? _value.end
          // ignore: cast_nullable_to_non_nullable
          : end as AttendanceTap?,
      minutes: minutes == const $CopyWithPlaceholder()
          ? _value.minutes
          // ignore: cast_nullable_to_non_nullable
          : minutes as int?,
    );
  }
}

extension $AttendanceDayCopyWith on AttendanceDay {
  /// Returns a callable class that can be used as follows: `instanceOfAttendanceDay.copyWith(...)` or like so:`instanceOfAttendanceDay.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$AttendanceDayCWProxy get copyWith => _$AttendanceDayCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AttendanceDay _$AttendanceDayFromJson(Map<String, dynamic> json) =>
    $checkedCreate('AttendanceDay', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['date', 'status', 'start']);
      final val = AttendanceDay(
        date: $checkedConvert('date', (v) => v as String),
        status: $checkedConvert(
          'status',
          (v) => $enumDecode(_$AttendanceStatusEnumMap, v),
        ),
        start: $checkedConvert(
          'start',
          (v) => AttendanceTap.fromJson(v as Map<String, dynamic>),
        ),
        end: $checkedConvert(
          'end',
          (v) => v == null
              ? null
              : AttendanceTap.fromJson(v as Map<String, dynamic>),
        ),
        minutes: $checkedConvert('minutes', (v) => (v as num?)?.toInt()),
      );
      return val;
    });

Map<String, dynamic> _$AttendanceDayToJson(AttendanceDay instance) =>
    <String, dynamic>{
      'date': instance.date,
      'status': _$AttendanceStatusEnumMap[instance.status]!,
      'start': instance.start.toJson(),
      'end': ?instance.end?.toJson(),
      'minutes': ?instance.minutes,
    };

const _$AttendanceStatusEnumMap = {
  AttendanceStatus.working: 'working',
  AttendanceStatus.ended: 'ended',
  AttendanceStatus.noCheckOut: 'no_check_out',
};
