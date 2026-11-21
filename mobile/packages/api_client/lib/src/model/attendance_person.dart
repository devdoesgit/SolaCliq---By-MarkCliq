//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api_client/src/model/role.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'attendance_person.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AttendancePerson {
  /// Returns a new [AttendancePerson] instance.
  AttendancePerson({
    required this.userId,

    required this.name,

    required this.role,

    required this.removed,
  });

  /// UUIDv7.
  @JsonKey(name: r'user_id', required: true, includeIfNull: false)
  final String userId;

  @JsonKey(name: r'name', required: true, includeIfNull: false)
  final String name;

  /// Their role now; `worker` or `agent` unless it changed after the days shown.
  @JsonKey(name: r'role', required: true, includeIfNull: false)
  final Role role;

  /// No longer a member; shown for the days they worked.
  @JsonKey(name: r'removed', required: true, includeIfNull: false)
  final bool removed;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is AttendancePerson &&
            runtimeType == other.runtimeType &&
            equals(
              [userId, name, role, removed],
              [other.userId, other.name, other.role, other.removed],
            );
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^ mapPropsToHashCode([userId, name, role, removed]);

  factory AttendancePerson.fromJson(Map<String, dynamic> json) =>
      _$AttendancePersonFromJson(json);

  Map<String, dynamic> toJson() => _$AttendancePersonToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
