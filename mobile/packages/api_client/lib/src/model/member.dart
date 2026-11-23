//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api_client/src/model/member_status.dart';
import 'package:api_client/src/model/role.dart';
import 'package:api_client/src/model/pay_type.dart';
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

    this.payType,

    required this.status,

    required this.addedAt,

    this.customers,

    this.openTasks,
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

  @JsonKey(name: r'pay_type', required: false, includeIfNull: false)
  final PayType? payType;

  @JsonKey(name: r'status', required: true, includeIfNull: false)
  final MemberStatus status;

  /// ISO 8601, UTC.
  @JsonKey(name: r'added_at', required: true, includeIfNull: false)
  final DateTime addedAt;

  /// Customers they registered that weren't turned down.
  @JsonKey(name: r'customers', required: false, includeIfNull: false)
  final int? customers;

  /// Their tasks not yet approved or cancelled, which stay with them if they're removed.
  @JsonKey(name: r'open_tasks', required: false, includeIfNull: false)
  final int? openTasks;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is Member &&
            runtimeType == other.runtimeType &&
            equals(
              [
                userId,
                name,
                email,
                role,
                payType,
                status,
                addedAt,
                customers,
                openTasks,
              ],
              [
                other.userId,
                other.name,
                other.email,
                other.role,
                other.payType,
                other.status,
                other.addedAt,
                other.customers,
                other.openTasks,
              ],
            );
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^
      mapPropsToHashCode([
        userId,
        name,
        email,
        role,
        payType,
        status,
        addedAt,
        customers,
        openTasks,
      ]);

  factory Member.fromJson(Map<String, dynamic> json) => _$MemberFromJson(json);

  Map<String, dynamic> toJson() => _$MemberToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
