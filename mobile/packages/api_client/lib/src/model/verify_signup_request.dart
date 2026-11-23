//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'verify_signup_request.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class VerifySignupRequest {
  /// Returns a new [VerifySignupRequest] instance.
  VerifySignupRequest({required this.email, required this.code});

  @JsonKey(name: r'email', required: true, includeIfNull: false)
  final String email;

  /// 6-digit code from the email.
  @JsonKey(name: r'code', required: true, includeIfNull: false)
  final String code;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is VerifySignupRequest &&
            runtimeType == other.runtimeType &&
            equals([email, code], [other.email, other.code]);
  }

  @override
  int get hashCode => runtimeType.hashCode ^ mapPropsToHashCode([email, code]);

  factory VerifySignupRequest.fromJson(Map<String, dynamic> json) =>
      _$VerifySignupRequestFromJson(json);

  Map<String, dynamic> toJson() => _$VerifySignupRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
