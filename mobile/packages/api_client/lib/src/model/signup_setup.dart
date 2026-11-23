//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'signup_setup.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class SignupSetup {
  /// Returns a new [SignupSetup] instance.
  SignupSetup({required this.signupToken, required this.expiresIn});

  /// Single use. Keep it in memory, never in storage or a URL.
  @JsonKey(name: r'signup_token', required: true, includeIfNull: false)
  final String signupToken;

  /// Seconds it works for.
  @JsonKey(name: r'expires_in', required: true, includeIfNull: false)
  final int expiresIn;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is SignupSetup &&
            runtimeType == other.runtimeType &&
            equals(
              [signupToken, expiresIn],
              [other.signupToken, other.expiresIn],
            );
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^ mapPropsToHashCode([signupToken, expiresIn]);

  factory SignupSetup.fromJson(Map<String, dynamic> json) =>
      _$SignupSetupFromJson(json);

  Map<String, dynamic> toJson() => _$SignupSetupToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
