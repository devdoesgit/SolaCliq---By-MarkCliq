//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api_client/src/model/attendance_month_view_people_inner.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'attendance_month_view.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AttendanceMonthView {
  /// Returns a new [AttendanceMonthView] instance.
  AttendanceMonthView({required this.month, required this.people});

  @JsonKey(name: r'month', required: true, includeIfNull: false)
  final String month;

  /// By name.
  @JsonKey(name: r'people', required: true, includeIfNull: false)
  final List<AttendanceMonthViewPeopleInner> people;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is AttendanceMonthView &&
            runtimeType == other.runtimeType &&
            equals([month, people], [other.month, other.people]);
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^ mapPropsToHashCode([month, people]);

  factory AttendanceMonthView.fromJson(Map<String, dynamic> json) =>
      _$AttendanceMonthViewFromJson(json);

  Map<String, dynamic> toJson() => _$AttendanceMonthViewToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
