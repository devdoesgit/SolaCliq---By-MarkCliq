//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'reset_password_request.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ResetPasswordRequest {
  /// Returns a new [ResetPasswordRequest] instance.
  ResetPasswordRequest({
    required this.email,

    required this.code,

    required this.newPassword,
  });

  @JsonKey(name: r'email', required: true, includeIfNull: false)
  final String email;

  /// 6-digit code from the email.
  @JsonKey(name: r'code', required: true, includeIfNull: false)
  final String code;

  /// At least 8 characters, including a number.
  @JsonKey(name: r'new_password', required: true, includeIfNull: false)
  final String newPassword;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is ResetPasswordRequest &&
            runtimeType == other.runtimeType &&
            equals(
              [email, code, newPassword],
              [other.email, other.code, other.newPassword],
            );
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^ mapPropsToHashCode([email, code, newPassword]);

  factory ResetPasswordRequest.fromJson(Map<String, dynamic> json) =>
      _$ResetPasswordRequestFromJson(json);

  Map<String, dynamic> toJson() => _$ResetPasswordRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
