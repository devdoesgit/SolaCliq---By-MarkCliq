//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api_client/src/model/role.dart';
import 'package:api_client/src/model/membership_org.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'membership.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class Membership {
  /// Returns a new [Membership] instance.
  Membership({required this.org, required this.role});

  @JsonKey(name: r'org', required: true, includeIfNull: false)
  final MembershipOrg org;

  @JsonKey(name: r'role', required: true, includeIfNull: false)
  final Role role;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is Membership &&
            runtimeType == other.runtimeType &&
            equals([org, role], [other.org, other.role]);
  }

  @override
  int get hashCode => runtimeType.hashCode ^ mapPropsToHashCode([org, role]);

  factory Membership.fromJson(Map<String, dynamic> json) =>
      _$MembershipFromJson(json);

  Map<String, dynamic> toJson() => _$MembershipToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
