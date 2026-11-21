//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'attendance_tap_create.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AttendanceTapCreate {
  /// Returns a new [AttendanceTapCreate] instance.
  AttendanceTapCreate({required this.phoneAt, required this.sentAt});

  /// The phone's clock when the person tapped.
  @JsonKey(name: r'phone_at', required: true, includeIfNull: false)
  final DateTime phoneAt;

  /// The phone's clock when the app sent this request: equal to `phone_at` when sent at once, later when it waited offline. Set again on each retry.
  @JsonKey(name: r'sent_at', required: true, includeIfNull: false)
  final DateTime sentAt;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is AttendanceTapCreate &&
            runtimeType == other.runtimeType &&
            equals([phoneAt, sentAt], [other.phoneAt, other.sentAt]);
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^ mapPropsToHashCode([phoneAt, sentAt]);

  factory AttendanceTapCreate.fromJson(Map<String, dynamic> json) =>
      _$AttendanceTapCreateFromJson(json);

  Map<String, dynamic> toJson() => _$AttendanceTapCreateToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
