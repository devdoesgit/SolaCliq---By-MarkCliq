//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api_client/src/model/pay_type.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'member_update.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class MemberUpdate {
  /// Returns a new [MemberUpdate] instance.
  MemberUpdate({this.role, this.payType});

  @JsonKey(name: r'role', required: false, includeIfNull: false)
  final MemberUpdateRoleEnum? role;

  @JsonKey(name: r'pay_type', required: false, includeIfNull: false)
  final PayType? payType;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is MemberUpdate &&
            runtimeType == other.runtimeType &&
            equals([role, payType], [other.role, other.payType]);
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^ mapPropsToHashCode([role, payType]);

  factory MemberUpdate.fromJson(Map<String, dynamic> json) =>
      _$MemberUpdateFromJson(json);

  Map<String, dynamic> toJson() => _$MemberUpdateToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum MemberUpdateRoleEnum {
  @JsonValue(r'worker')
  worker(r'worker'),
  @JsonValue(r'agent')
  agent(r'agent');

  const MemberUpdateRoleEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
