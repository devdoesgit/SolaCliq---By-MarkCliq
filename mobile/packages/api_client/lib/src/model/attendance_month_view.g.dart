// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'attendance_month_view.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$AttendanceMonthViewCWProxy {
  AttendanceMonthView month(String month);

  AttendanceMonthView people(List<AttendanceMonthViewPeopleInner> people);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `AttendanceMonthView(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// AttendanceMonthView(...).copyWith(id: 12, name: "My name")
  /// ````
  AttendanceMonthView call({
    String month,
    List<AttendanceMonthViewPeopleInner> people,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfAttendanceMonthView.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfAttendanceMonthView.copyWith.fieldName(...)`
class _$AttendanceMonthViewCWProxyImpl implements _$AttendanceMonthViewCWProxy {
  const _$AttendanceMonthViewCWProxyImpl(this._value);

  final AttendanceMonthView _value;

  @override
  AttendanceMonthView month(String month) => this(month: month);

  @override
  AttendanceMonthView people(List<AttendanceMonthViewPeopleInner> people) =>
      this(people: people);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `AttendanceMonthView(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// AttendanceMonthView(...).copyWith(id: 12, name: "My name")
  /// ````
  AttendanceMonthView call({
    Object? month = const $CopyWithPlaceholder(),
    Object? people = const $CopyWithPlaceholder(),
  }) {
    return AttendanceMonthView(
      month: month == const $CopyWithPlaceholder()
          ? _value.month
          // ignore: cast_nullable_to_non_nullable
          : month as String,
      people: people == const $CopyWithPlaceholder()
          ? _value.people
          // ignore: cast_nullable_to_non_nullable
          : people as List<AttendanceMonthViewPeopleInner>,
    );
  }
}

extension $AttendanceMonthViewCopyWith on AttendanceMonthView {
  /// Returns a callable class that can be used as follows: `instanceOfAttendanceMonthView.copyWith(...)` or like so:`instanceOfAttendanceMonthView.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$AttendanceMonthViewCWProxy get copyWith =>
      _$AttendanceMonthViewCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AttendanceMonthView _$AttendanceMonthViewFromJson(Map<String, dynamic> json) =>
    $checkedCreate('AttendanceMonthView', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['month', 'people']);
      final val = AttendanceMonthView(
        month: $checkedConvert('month', (v) => v as String),
        people: $checkedConvert(
          'people',
          (v) => (v as List<dynamic>)
              .map(
                (e) => AttendanceMonthViewPeopleInner.fromJson(
                  e as Map<String, dynamic>,
                ),
              )
              .toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$AttendanceMonthViewToJson(
  AttendanceMonthView instance,
) => <String, dynamic>{
  'month': instance.month,
  'people': instance.people.map((e) => e.toJson()).toList(),
};
