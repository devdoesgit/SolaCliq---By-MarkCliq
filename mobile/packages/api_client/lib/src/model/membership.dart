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
  Membership({required this.org, required this.role, this.payType});

  @JsonKey(name: r'org', required: true, includeIfNull: false)
  final MembershipOrg org;

  @JsonKey(name: r'role', required: true, includeIfNull: false)
  final Role role;

  /// Agents (shown as Sales) only. `commission` agents enter a commission on each customer they add; `salary` employees have no commission step.
  @JsonKey(name: r'pay_type', required: false, includeIfNull: false)
  final MembershipPayTypeEnum? payType;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is Membership &&
            runtimeType == other.runtimeType &&
            equals(
              [org, role, payType],
              [other.org, other.role, other.payType],
            );
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^ mapPropsToHashCode([org, role, payType]);

  factory Membership.fromJson(Map<String, dynamic> json) =>
      _$MembershipFromJson(json);

  Map<String, dynamic> toJson() => _$MembershipToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

/// Agents (shown as Sales) only. `commission` agents enter a commission on each customer they add; `salary` employees have no commission step.
enum MembershipPayTypeEnum {
  @JsonValue(r'commission')
  commission(r'commission'),
  @JsonValue(r'salary')
  salary(r'salary');

  const MembershipPayTypeEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
