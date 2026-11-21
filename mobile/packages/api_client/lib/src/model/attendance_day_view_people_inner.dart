//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api_client/src/model/attendance_person.dart';
import 'package:api_client/src/model/attendance_day.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'attendance_day_view_people_inner.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AttendanceDayViewPeopleInner {
  /// Returns a new [AttendanceDayViewPeopleInner] instance.
  AttendanceDayViewPeopleInner({required this.person, this.day});

  @JsonKey(name: r'person', required: true, includeIfNull: false)
  final AttendancePerson person;

  /// Absent when they haven't started on this date.
  @JsonKey(name: r'day', required: false, includeIfNull: false)
  final AttendanceDay? day;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is AttendanceDayViewPeopleInner &&
            runtimeType == other.runtimeType &&
            equals([person, day], [other.person, other.day]);
  }

  @override
  int get hashCode => runtimeType.hashCode ^ mapPropsToHashCode([person, day]);

  factory AttendanceDayViewPeopleInner.fromJson(Map<String, dynamic> json) =>
      _$AttendanceDayViewPeopleInnerFromJson(json);

  Map<String, dynamic> toJson() => _$AttendanceDayViewPeopleInnerToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
