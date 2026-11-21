//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api_client/src/model/attendance_person.dart';
import 'package:api_client/src/model/attendance_day.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'attendance_month_view_people_inner.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AttendanceMonthViewPeopleInner {
  /// Returns a new [AttendanceMonthViewPeopleInner] instance.
  AttendanceMonthViewPeopleInner({
    required this.person,

    required this.days,

    required this.daysWorked,

    required this.minutes,
  });

  @JsonKey(name: r'person', required: true, includeIfNull: false)
  final AttendancePerson person;

  /// Only dates with a start, oldest first.
  @JsonKey(name: r'days', required: true, includeIfNull: false)
  final List<AttendanceDay> days;

  /// Days with a start.
  // minimum: 0
  @JsonKey(name: r'days_worked', required: true, includeIfNull: false)
  final int daysWorked;

  /// Total worked time of the ended days.
  // minimum: 0
  @JsonKey(name: r'minutes', required: true, includeIfNull: false)
  final int minutes;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is AttendanceMonthViewPeopleInner &&
            runtimeType == other.runtimeType &&
            equals(
              [person, days, daysWorked, minutes],
              [other.person, other.days, other.daysWorked, other.minutes],
            );
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^
      mapPropsToHashCode([person, days, daysWorked, minutes]);

  factory AttendanceMonthViewPeopleInner.fromJson(Map<String, dynamic> json) =>
      _$AttendanceMonthViewPeopleInnerFromJson(json);

  Map<String, dynamic> toJson() => _$AttendanceMonthViewPeopleInnerToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
