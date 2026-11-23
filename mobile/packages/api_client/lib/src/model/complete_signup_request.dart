//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'complete_signup_request.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class CompleteSignupRequest {
  /// Returns a new [CompleteSignupRequest] instance.
  CompleteSignupRequest({
    required this.signupToken,

    required this.name,

    this.phone,

    required this.password,

    required this.termsVersion,
  });

  @JsonKey(name: r'signup_token', required: true, includeIfNull: false)
  final String signupToken;

  @JsonKey(name: r'name', required: true, includeIfNull: false)
  final String name;

  /// Indian mobile number, 10 digits, without +91.
  @JsonKey(name: r'phone', required: false, includeIfNull: false)
  final String? phone;

  /// At least 8 characters, including a number.
  @JsonKey(name: r'password', required: true, includeIfNull: false)
  final String password;

  /// The version of the Terms of Use and Privacy Policy the person ticked to agree to (F16). Left out, or above the current version, is 422 `terms.required`. An older one is recorded as it is; the app then asks again after login (`Me.terms`).
  // minimum: 1
  @JsonKey(name: r'terms_version', required: true, includeIfNull: false)
  final int termsVersion;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is CompleteSignupRequest &&
            runtimeType == other.runtimeType &&
            equals(
              [signupToken, name, phone, password, termsVersion],
              [
                other.signupToken,
                other.name,
                other.phone,
                other.password,
                other.termsVersion,
              ],
            );
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^
      mapPropsToHashCode([signupToken, name, phone, password, termsVersion]);

  factory CompleteSignupRequest.fromJson(Map<String, dynamic> json) =>
      _$CompleteSignupRequestFromJson(json);

  Map<String, dynamic> toJson() => _$CompleteSignupRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
