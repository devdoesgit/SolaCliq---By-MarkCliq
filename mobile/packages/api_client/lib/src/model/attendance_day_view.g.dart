// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'attendance_day_view.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$AttendanceDayViewCWProxy {
  AttendanceDayView date(String date);

  AttendanceDayView people(List<AttendanceDayViewPeopleInner> people);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `AttendanceDayView(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// AttendanceDayView(...).copyWith(id: 12, name: "My name")
  /// ````
  AttendanceDayView call({
    String date,
    List<AttendanceDayViewPeopleInner> people,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfAttendanceDayView.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfAttendanceDayView.copyWith.fieldName(...)`
class _$AttendanceDayViewCWProxyImpl implements _$AttendanceDayViewCWProxy {
  const _$AttendanceDayViewCWProxyImpl(this._value);

  final AttendanceDayView _value;

  @override
  AttendanceDayView date(String date) => this(date: date);

  @override
  AttendanceDayView people(List<AttendanceDayViewPeopleInner> people) =>
      this(people: people);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `AttendanceDayView(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// AttendanceDayView(...).copyWith(id: 12, name: "My name")
  /// ````
  AttendanceDayView call({
    Object? date = const $CopyWithPlaceholder(),
    Object? people = const $CopyWithPlaceholder(),
  }) {
    return AttendanceDayView(
      date: date == const $CopyWithPlaceholder()
          ? _value.date
          // ignore: cast_nullable_to_non_nullable
          : date as String,
      people: people == const $CopyWithPlaceholder()
          ? _value.people
          // ignore: cast_nullable_to_non_nullable
          : people as List<AttendanceDayViewPeopleInner>,
    );
  }
}

extension $AttendanceDayViewCopyWith on AttendanceDayView {
  /// Returns a callable class that can be used as follows: `instanceOfAttendanceDayView.copyWith(...)` or like so:`instanceOfAttendanceDayView.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$AttendanceDayViewCWProxy get copyWith =>
      _$AttendanceDayViewCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AttendanceDayView _$AttendanceDayViewFromJson(Map<String, dynamic> json) =>
    $checkedCreate('AttendanceDayView', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['date', 'people']);
      final val = AttendanceDayView(
        date: $checkedConvert('date', (v) => v as String),
        people: $checkedConvert(
          'people',
          (v) => (v as List<dynamic>)
              .map(
                (e) => AttendanceDayViewPeopleInner.fromJson(
                  e as Map<String, dynamic>,
                ),
              )
              .toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$AttendanceDayViewToJson(AttendanceDayView instance) =>
    <String, dynamic>{
      'date': instance.date,
      'people': instance.people.map((e) => e.toJson()).toList(),
    };
