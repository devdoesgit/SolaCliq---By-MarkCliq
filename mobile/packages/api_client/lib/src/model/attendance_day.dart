//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api_client/src/model/attendance_tap.dart';
import 'package:api_client/src/model/attendance_status.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'attendance_day.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AttendanceDay {
  /// Returns a new [AttendanceDay] instance.
  AttendanceDay({
    required this.date,

    required this.status,

    required this.start,

    this.end,

    this.minutes,
  });

  /// The India date the day started.
  @JsonKey(name: r'date', required: true, includeIfNull: false)
  final String date;

  @JsonKey(name: r'status', required: true, includeIfNull: false)
  final AttendanceStatus status;

  @JsonKey(name: r'start', required: true, includeIfNull: false)
  final AttendanceTap start;

  @JsonKey(name: r'end', required: false, includeIfNull: false)
  final AttendanceTap? end;

  /// Worked time, end minus start; present once ended.
  // minimum: 0
  @JsonKey(name: r'minutes', required: false, includeIfNull: false)
  final int? minutes;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is AttendanceDay &&
            runtimeType == other.runtimeType &&
            equals(
              [date, status, start, end, minutes],
              [other.date, other.status, other.start, other.end, other.minutes],
            );
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^
      mapPropsToHashCode([date, status, start, end, minutes]);

  factory AttendanceDay.fromJson(Map<String, dynamic> json) =>
      _$AttendanceDayFromJson(json);

  Map<String, dynamic> toJson() => _$AttendanceDayToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
