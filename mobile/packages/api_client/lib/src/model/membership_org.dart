//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api_client/src/model/org_status.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'membership_org.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class MembershipOrg {
  /// Returns a new [MembershipOrg] instance.
  MembershipOrg({
    required this.id,

    required this.name,

    required this.status,

    this.phone,
  });

  /// UUIDv7.
  @JsonKey(name: r'id', required: true, includeIfNull: false)
  final String id;

  @JsonKey(name: r'name', required: true, includeIfNull: false)
  final String name;

  @JsonKey(name: r'status', required: true, includeIfNull: false)
  final OrgStatus status;

  /// The company's number, for its people to call.
  @JsonKey(name: r'phone', required: false, includeIfNull: false)
  final String? phone;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is MembershipOrg &&
            runtimeType == other.runtimeType &&
            equals(
              [id, name, status, phone],
              [other.id, other.name, other.status, other.phone],
            );
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^ mapPropsToHashCode([id, name, status, phone]);

  factory MembershipOrg.fromJson(Map<String, dynamic> json) =>
      _$MembershipOrgFromJson(json);

  Map<String, dynamic> toJson() => _$MembershipOrgToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
