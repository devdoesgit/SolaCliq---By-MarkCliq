//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api_client/src/model/member_status.dart';
import 'package:api_client/src/model/role.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'member.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class Member {
  /// Returns a new [Member] instance.
  Member({
    required this.userId,

    required this.name,

    required this.email,

    required this.role,

    required this.status,

    required this.addedAt,
  });

  /// UUIDv7.
  @JsonKey(name: r'user_id', required: true, includeIfNull: false)
  final String userId;

  @JsonKey(name: r'name', required: true, includeIfNull: false)
  final String name;

  @JsonKey(name: r'email', required: true, includeIfNull: false)
  final String email;

  @JsonKey(name: r'role', required: true, includeIfNull: false)
  final Role role;

  @JsonKey(name: r'status', required: true, includeIfNull: false)
  final MemberStatus status;

  /// ISO 8601, UTC.
  @JsonKey(name: r'added_at', required: true, includeIfNull: false)
  final DateTime addedAt;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is Member &&
            runtimeType == other.runtimeType &&
            equals(
              [userId, name, email, role, status, addedAt],
              [
                other.userId,
                other.name,
                other.email,
                other.role,
                other.status,
                other.addedAt,
              ],
            );
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^
      mapPropsToHashCode([userId, name, email, role, status, addedAt]);

  factory Member.fromJson(Map<String, dynamic> json) => _$MemberFromJson(json);

  Map<String, dynamic> toJson() => _$MemberToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
