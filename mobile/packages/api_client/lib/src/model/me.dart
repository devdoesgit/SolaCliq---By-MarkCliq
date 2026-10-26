//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api_client/src/model/membership.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'me.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class Me {
  /// Returns a new [Me] instance.
  Me({
    required this.id,

    required this.name,

    required this.email,

    this.phone,

    required this.emailVerified,

    required this.isPlatformAdmin,

    required this.memberships,
  });

  /// UUIDv7.
  @JsonKey(name: r'id', required: true, includeIfNull: false)
  final String id;

  @JsonKey(name: r'name', required: true, includeIfNull: false)
  final String name;

  @JsonKey(name: r'email', required: true, includeIfNull: false)
  final String email;

  /// Indian mobile number, 10 digits, without +91.
  @JsonKey(name: r'phone', required: false, includeIfNull: false)
  final String? phone;

  @JsonKey(name: r'email_verified', required: true, includeIfNull: false)
  final bool emailVerified;

  @JsonKey(name: r'is_platform_admin', required: true, includeIfNull: false)
  final bool isPlatformAdmin;

  @JsonKey(name: r'memberships', required: true, includeIfNull: false)
  final List<Membership> memberships;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is Me &&
            runtimeType == other.runtimeType &&
            equals(
              [
                id,
                name,
                email,
                phone,
                emailVerified,
                isPlatformAdmin,
                memberships,
              ],
              [
                other.id,
                other.name,
                other.email,
                other.phone,
                other.emailVerified,
                other.isPlatformAdmin,
                other.memberships,
              ],
            );
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^
      mapPropsToHashCode([
        id,
        name,
        email,
        phone,
        emailVerified,
        isPlatformAdmin,
        memberships,
      ]);

  factory Me.fromJson(Map<String, dynamic> json) => _$MeFromJson(json);

  Map<String, dynamic> toJson() => _$MeToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
