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
  MembershipOrg({required this.id, required this.name, required this.status});

  /// UUIDv7.
  @JsonKey(name: r'id', required: true, includeIfNull: false)
  final String id;

  @JsonKey(name: r'name', required: true, includeIfNull: false)
  final String name;

  @JsonKey(name: r'status', required: true, includeIfNull: false)
  final OrgStatus status;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is MembershipOrg &&
            runtimeType == other.runtimeType &&
            equals([id, name, status], [other.id, other.name, other.status]);
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^ mapPropsToHashCode([id, name, status]);

  factory MembershipOrg.fromJson(Map<String, dynamic> json) =>
      _$MembershipOrgFromJson(json);

  Map<String, dynamic> toJson() => _$MembershipOrgToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
