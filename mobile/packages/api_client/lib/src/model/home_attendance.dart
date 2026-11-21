//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api_client/src/model/attendance_day.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'home_attendance.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class HomeAttendance {
  /// Returns a new [HomeAttendance] instance.
  HomeAttendance({required this.state, this.day});

  /// Today in India. `not_started`: no day today (yesterday's, even without an end, doesn't count); `working`: today's `day` has no end yet; `ended`: today's `day` has ended.
  @JsonKey(name: r'state', required: true, includeIfNull: false)
  final HomeAttendanceStateEnum state;

  @JsonKey(name: r'day', required: false, includeIfNull: false)
  final AttendanceDay? day;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is HomeAttendance &&
            runtimeType == other.runtimeType &&
            equals([state, day], [other.state, other.day]);
  }

  @override
  int get hashCode => runtimeType.hashCode ^ mapPropsToHashCode([state, day]);

  factory HomeAttendance.fromJson(Map<String, dynamic> json) =>
      _$HomeAttendanceFromJson(json);

  Map<String, dynamic> toJson() => _$HomeAttendanceToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

/// Today in India. `not_started`: no day today (yesterday's, even without an end, doesn't count); `working`: today's `day` has no end yet; `ended`: today's `day` has ended.
enum HomeAttendanceStateEnum {
  @JsonValue(r'not_started')
  notStarted(r'not_started'),
  @JsonValue(r'working')
  working(r'working'),
  @JsonValue(r'ended')
  ended(r'ended');

  const HomeAttendanceStateEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
