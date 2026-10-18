//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'verify_email_request.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class VerifyEmailRequest {
  /// Returns a new [VerifyEmailRequest] instance.
  VerifyEmailRequest({required this.email, required this.code});

  @JsonKey(name: r'email', required: true, includeIfNull: false)
  final String email;

  /// 6-digit code from the email.
  @JsonKey(name: r'code', required: true, includeIfNull: false)
  final String code;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is VerifyEmailRequest &&
            runtimeType == other.runtimeType &&
            equals([email, code], [other.email, other.code]);
  }

  @override
  int get hashCode => runtimeType.hashCode ^ mapPropsToHashCode([email, code]);

  factory VerifyEmailRequest.fromJson(Map<String, dynamic> json) =>
      _$VerifyEmailRequestFromJson(json);

  Map<String, dynamic> toJson() => _$VerifyEmailRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
