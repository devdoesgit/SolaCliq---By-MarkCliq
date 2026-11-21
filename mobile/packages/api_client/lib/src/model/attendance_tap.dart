//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'attendance_tap.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AttendanceTap {
  /// Returns a new [AttendanceTap] instance.
  AttendanceTap({required this.at, required this.sentLate});

  /// ISO 8601, UTC.
  @JsonKey(name: r'at', required: true, includeIfNull: false)
  final DateTime at;

  /// Waited over 5 minutes on the phone (sent from offline); how long it waited is the phone's word.
  @JsonKey(name: r'sent_late', required: true, includeIfNull: false)
  final bool sentLate;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is AttendanceTap &&
            runtimeType == other.runtimeType &&
            equals([at, sentLate], [other.at, other.sentLate]);
  }

  @override
  int get hashCode => runtimeType.hashCode ^ mapPropsToHashCode([at, sentLate]);

  factory AttendanceTap.fromJson(Map<String, dynamic> json) =>
      _$AttendanceTapFromJson(json);

  Map<String, dynamic> toJson() => _$AttendanceTapToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
