//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'login_request.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class LoginRequest {
  /// Returns a new [LoginRequest] instance.
  LoginRequest({
    required this.email,

    required this.password,

    required this.client,
  });

  @JsonKey(name: r'email', required: true, includeIfNull: false)
  final String email;

  @JsonKey(name: r'password', required: true, includeIfNull: false)
  final String password;

  /// `app` gets tokens in the body; `web` gets a session cookie.
  @JsonKey(name: r'client', required: true, includeIfNull: false)
  final LoginRequestClientEnum client;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is LoginRequest &&
            runtimeType == other.runtimeType &&
            equals(
              [email, password, client],
              [other.email, other.password, other.client],
            );
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^ mapPropsToHashCode([email, password, client]);

  factory LoginRequest.fromJson(Map<String, dynamic> json) =>
      _$LoginRequestFromJson(json);

  Map<String, dynamic> toJson() => _$LoginRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

/// `app` gets tokens in the body; `web` gets a session cookie.
enum LoginRequestClientEnum {
  @JsonValue(r'app')
  app(r'app'),
  @JsonValue(r'web')
  web(r'web');

  const LoginRequestClientEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
