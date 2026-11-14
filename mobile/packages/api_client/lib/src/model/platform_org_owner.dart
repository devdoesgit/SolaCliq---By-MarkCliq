//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'platform_org_owner.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PlatformOrgOwner {
  /// Returns a new [PlatformOrgOwner] instance.
  PlatformOrgOwner({
    required this.userId,

    required this.name,

    required this.email,

    this.phone,
  });

  /// UUIDv7.
  @JsonKey(name: r'user_id', required: true, includeIfNull: false)
  final String userId;

  @JsonKey(name: r'name', required: true, includeIfNull: false)
  final String name;

  @JsonKey(name: r'email', required: true, includeIfNull: false)
  final String email;

  /// Indian mobile number, 10 digits, without +91.
  @JsonKey(name: r'phone', required: false, includeIfNull: false)
  final String? phone;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is PlatformOrgOwner &&
            runtimeType == other.runtimeType &&
            equals(
              [userId, name, email, phone],
              [other.userId, other.name, other.email, other.phone],
            );
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^ mapPropsToHashCode([userId, name, email, phone]);

  factory PlatformOrgOwner.fromJson(Map<String, dynamic> json) =>
      _$PlatformOrgOwnerFromJson(json);

  Map<String, dynamic> toJson() => _$PlatformOrgOwnerToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
