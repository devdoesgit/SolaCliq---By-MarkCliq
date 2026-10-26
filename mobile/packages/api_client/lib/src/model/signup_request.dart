//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'signup_request.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class SignupRequest {
  /// Returns a new [SignupRequest] instance.
  SignupRequest({
    required this.name,

    required this.email,

    this.phone,

    required this.password,
  });

  @JsonKey(name: r'name', required: true, includeIfNull: false)
  final String name;

  @JsonKey(name: r'email', required: true, includeIfNull: false)
  final String email;

  /// Indian mobile number, 10 digits, without +91.
  @JsonKey(name: r'phone', required: false, includeIfNull: false)
  final String? phone;

  /// At least 8 characters, including a number.
  @JsonKey(name: r'password', required: true, includeIfNull: false)
  final String password;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is SignupRequest &&
            runtimeType == other.runtimeType &&
            equals(
              [name, email, phone, password],
              [other.name, other.email, other.phone, other.password],
            );
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^ mapPropsToHashCode([name, email, phone, password]);

  factory SignupRequest.fromJson(Map<String, dynamic> json) =>
      _$SignupRequestFromJson(json);

  Map<String, dynamic> toJson() => _$SignupRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
