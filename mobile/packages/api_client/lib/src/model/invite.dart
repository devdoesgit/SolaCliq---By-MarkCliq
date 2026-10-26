//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api_client/src/model/role.dart';
import 'package:api_client/src/model/invite_org.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'invite.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class Invite {
  /// Returns a new [Invite] instance.
  Invite({
    required this.id,

    required this.org,

    required this.role,

    required this.invitedBy,

    required this.invitedAt,
  });

  /// UUIDv7.
  @JsonKey(name: r'id', required: true, includeIfNull: false)
  final String id;

  @JsonKey(name: r'org', required: true, includeIfNull: false)
  final InviteOrg org;

  @JsonKey(name: r'role', required: true, includeIfNull: false)
  final Role role;

  /// Name of the admin who sent it.
  @JsonKey(name: r'invited_by', required: true, includeIfNull: false)
  final String invitedBy;

  /// ISO 8601, UTC.
  @JsonKey(name: r'invited_at', required: true, includeIfNull: false)
  final DateTime invitedAt;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is Invite &&
            runtimeType == other.runtimeType &&
            equals(
              [id, org, role, invitedBy, invitedAt],
              [
                other.id,
                other.org,
                other.role,
                other.invitedBy,
                other.invitedAt,
              ],
            );
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^
      mapPropsToHashCode([id, org, role, invitedBy, invitedAt]);

  factory Invite.fromJson(Map<String, dynamic> json) => _$InviteFromJson(json);

  Map<String, dynamic> toJson() => _$InviteToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
