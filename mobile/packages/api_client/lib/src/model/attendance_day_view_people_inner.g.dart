// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'attendance_day_view_people_inner.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$AttendanceDayViewPeopleInnerCWProxy {
  AttendanceDayViewPeopleInner person(AttendancePerson person);

  AttendanceDayViewPeopleInner day(AttendanceDay? day);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `AttendanceDayViewPeopleInner(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// AttendanceDayViewPeopleInner(...).copyWith(id: 12, name: "My name")
  /// ````
  AttendanceDayViewPeopleInner call({
    AttendancePerson person,
    AttendanceDay? day,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfAttendanceDayViewPeopleInner.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfAttendanceDayViewPeopleInner.copyWith.fieldName(...)`
class _$AttendanceDayViewPeopleInnerCWProxyImpl
    implements _$AttendanceDayViewPeopleInnerCWProxy {
  const _$AttendanceDayViewPeopleInnerCWProxyImpl(this._value);

  final AttendanceDayViewPeopleInner _value;

  @override
  AttendanceDayViewPeopleInner person(AttendancePerson person) =>
      this(person: person);

  @override
  AttendanceDayViewPeopleInner day(AttendanceDay? day) => this(day: day);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `AttendanceDayViewPeopleInner(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// AttendanceDayViewPeopleInner(...).copyWith(id: 12, name: "My name")
  /// ````
  AttendanceDayViewPeopleInner call({
    Object? person = const $CopyWithPlaceholder(),
    Object? day = const $CopyWithPlaceholder(),
  }) {
    return AttendanceDayViewPeopleInner(
      person: person == const $CopyWithPlaceholder()
          ? _value.person
          // ignore: cast_nullable_to_non_nullable
          : person as AttendancePerson,
      day: day == const $CopyWithPlaceholder()
          ? _value.day
          // ignore: cast_nullable_to_non_nullable
          : day as AttendanceDay?,
    );
  }
}

extension $AttendanceDayViewPeopleInnerCopyWith
    on AttendanceDayViewPeopleInner {
  /// Returns a callable class that can be used as follows: `instanceOfAttendanceDayViewPeopleInner.copyWith(...)` or like so:`instanceOfAttendanceDayViewPeopleInner.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$AttendanceDayViewPeopleInnerCWProxy get copyWith =>
      _$AttendanceDayViewPeopleInnerCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AttendanceDayViewPeopleInner _$AttendanceDayViewPeopleInnerFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('AttendanceDayViewPeopleInner', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['person']);
  final val = AttendanceDayViewPeopleInner(
    person: $checkedConvert(
      'person',
      (v) => AttendancePerson.fromJson(v as Map<String, dynamic>),
    ),
    day: $checkedConvert(
      'day',
      (v) =>
          v == null ? null : AttendanceDay.fromJson(v as Map<String, dynamic>),
    ),
  );
  return val;
});

Map<String, dynamic> _$AttendanceDayViewPeopleInnerToJson(
  AttendanceDayViewPeopleInner instance,
) => <String, dynamic>{
  'person': instance.person.toJson(),
  'day': ?instance.day?.toJson(),
};
