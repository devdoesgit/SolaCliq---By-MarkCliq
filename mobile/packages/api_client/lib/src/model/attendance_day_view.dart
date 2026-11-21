//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api_client/src/model/attendance_day_view_people_inner.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'attendance_day_view.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AttendanceDayView {
  /// Returns a new [AttendanceDayView] instance.
  AttendanceDayView({required this.date, required this.people});

  @JsonKey(name: r'date', required: true, includeIfNull: false)
  final String date;

  /// By name.
  @JsonKey(name: r'people', required: true, includeIfNull: false)
  final List<AttendanceDayViewPeopleInner> people;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is AttendanceDayView &&
            runtimeType == other.runtimeType &&
            equals([date, people], [other.date, other.people]);
  }

  @override
  int get hashCode => runtimeType.hashCode ^ mapPropsToHashCode([date, people]);

  factory AttendanceDayView.fromJson(Map<String, dynamic> json) =>
      _$AttendanceDayViewFromJson(json);

  Map<String, dynamic> toJson() => _$AttendanceDayViewToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
