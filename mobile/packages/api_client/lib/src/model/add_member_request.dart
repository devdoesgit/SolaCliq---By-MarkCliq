//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api_client/src/model/role.dart';
import 'package:api_client/src/model/pay_type.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'add_member_request.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AddMemberRequest {
  /// Returns a new [AddMemberRequest] instance.
  AddMemberRequest({
    required this.name,

    required this.email,

    required this.role,

    this.payType,
  });

  @JsonKey(name: r'name', required: true, includeIfNull: false)
  final String name;

  @JsonKey(name: r'email', required: true, includeIfNull: false)
  final String email;

  @JsonKey(name: r'role', required: true, includeIfNull: false)
  final Role role;

  @JsonKey(name: r'pay_type', required: false, includeIfNull: false)
  final PayType? payType;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is AddMemberRequest &&
            runtimeType == other.runtimeType &&
            equals(
              [name, email, role, payType],
              [other.name, other.email, other.role, other.payType],
            );
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^ mapPropsToHashCode([name, email, role, payType]);

  factory AddMemberRequest.fromJson(Map<String, dynamic> json) =>
      _$AddMemberRequestFromJson(json);

  Map<String, dynamic> toJson() => _$AddMemberRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
