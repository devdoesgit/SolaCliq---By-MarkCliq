//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api_client/src/model/role.dart';
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
  });

  @JsonKey(name: r'name', required: true, includeIfNull: false)
  final String name;

  @JsonKey(name: r'email', required: true, includeIfNull: false)
  final String email;

  @JsonKey(name: r'role', required: true, includeIfNull: false)
  final Role role;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is AddMemberRequest &&
            runtimeType == other.runtimeType &&
            equals([name, email, role], [other.name, other.email, other.role]);
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^ mapPropsToHashCode([name, email, role]);

  factory AddMemberRequest.fromJson(Map<String, dynamic> json) =>
      _$AddMemberRequestFromJson(json);

  Map<String, dynamic> toJson() => _$AddMemberRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
