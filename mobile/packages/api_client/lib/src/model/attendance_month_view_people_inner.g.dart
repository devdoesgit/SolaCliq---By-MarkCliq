// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'attendance_month_view_people_inner.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$AttendanceMonthViewPeopleInnerCWProxy {
  AttendanceMonthViewPeopleInner person(AttendancePerson person);

  AttendanceMonthViewPeopleInner days(List<AttendanceDay> days);

  AttendanceMonthViewPeopleInner daysWorked(int daysWorked);

  AttendanceMonthViewPeopleInner minutes(int minutes);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `AttendanceMonthViewPeopleInner(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// AttendanceMonthViewPeopleInner(...).copyWith(id: 12, name: "My name")
  /// ````
  AttendanceMonthViewPeopleInner call({
    AttendancePerson person,
    List<AttendanceDay> days,
    int daysWorked,
    int minutes,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfAttendanceMonthViewPeopleInner.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfAttendanceMonthViewPeopleInner.copyWith.fieldName(...)`
class _$AttendanceMonthViewPeopleInnerCWProxyImpl
    implements _$AttendanceMonthViewPeopleInnerCWProxy {
  const _$AttendanceMonthViewPeopleInnerCWProxyImpl(this._value);

  final AttendanceMonthViewPeopleInner _value;

  @override
  AttendanceMonthViewPeopleInner person(AttendancePerson person) =>
      this(person: person);

  @override
  AttendanceMonthViewPeopleInner days(List<AttendanceDay> days) =>
      this(days: days);

  @override
  AttendanceMonthViewPeopleInner daysWorked(int daysWorked) =>
      this(daysWorked: daysWorked);

  @override
  AttendanceMonthViewPeopleInner minutes(int minutes) => this(minutes: minutes);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `AttendanceMonthViewPeopleInner(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// AttendanceMonthViewPeopleInner(...).copyWith(id: 12, name: "My name")
  /// ````
  AttendanceMonthViewPeopleInner call({
    Object? person = const $CopyWithPlaceholder(),
    Object? days = const $CopyWithPlaceholder(),
    Object? daysWorked = const $CopyWithPlaceholder(),
    Object? minutes = const $CopyWithPlaceholder(),
  }) {
    return AttendanceMonthViewPeopleInner(
      person: person == const $CopyWithPlaceholder()
          ? _value.person
          // ignore: cast_nullable_to_non_nullable
          : person as AttendancePerson,
      days: days == const $CopyWithPlaceholder()
          ? _value.days
          // ignore: cast_nullable_to_non_nullable
          : days as List<AttendanceDay>,
      daysWorked: daysWorked == const $CopyWithPlaceholder()
          ? _value.daysWorked
          // ignore: cast_nullable_to_non_nullable
          : daysWorked as int,
      minutes: minutes == const $CopyWithPlaceholder()
          ? _value.minutes
          // ignore: cast_nullable_to_non_nullable
          : minutes as int,
    );
  }
}

extension $AttendanceMonthViewPeopleInnerCopyWith
    on AttendanceMonthViewPeopleInner {
  /// Returns a callable class that can be used as follows: `instanceOfAttendanceMonthViewPeopleInner.copyWith(...)` or like so:`instanceOfAttendanceMonthViewPeopleInner.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$AttendanceMonthViewPeopleInnerCWProxy get copyWith =>
      _$AttendanceMonthViewPeopleInnerCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AttendanceMonthViewPeopleInner _$AttendanceMonthViewPeopleInnerFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('AttendanceMonthViewPeopleInner', json, ($checkedConvert) {
  $checkKeys(
    json,
    requiredKeys: const ['person', 'days', 'days_worked', 'minutes'],
  );
  final val = AttendanceMonthViewPeopleInner(
    person: $checkedConvert(
      'person',
      (v) => AttendancePerson.fromJson(v as Map<String, dynamic>),
    ),
    days: $checkedConvert(
      'days',
      (v) => (v as List<dynamic>)
          .map((e) => AttendanceDay.fromJson(e as Map<String, dynamic>))
          .toList(),
    ),
    daysWorked: $checkedConvert('days_worked', (v) => (v as num).toInt()),
    minutes: $checkedConvert('minutes', (v) => (v as num).toInt()),
  );
  return val;
}, fieldKeyMap: const {'daysWorked': 'days_worked'});

Map<String, dynamic> _$AttendanceMonthViewPeopleInnerToJson(
  AttendanceMonthViewPeopleInner instance,
) => <String, dynamic>{
  'person': instance.person.toJson(),
  'days': instance.days.map((e) => e.toJson()).toList(),
  'days_worked': instance.daysWorked,
  'minutes': instance.minutes,
};
