//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api_client/src/model/token_pair.dart';
import 'package:api_client/src/model/me.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'login_response.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class LoginResponse {
  /// Returns a new [LoginResponse] instance.
  LoginResponse({required this.user, this.tokens});

  @JsonKey(name: r'user', required: true, includeIfNull: false)
  final Me user;

  /// Present for `client: app` only.
  @JsonKey(name: r'tokens', required: false, includeIfNull: false)
  final TokenPair? tokens;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is LoginResponse &&
            runtimeType == other.runtimeType &&
            equals([user, tokens], [other.user, other.tokens]);
  }

  @override
  int get hashCode => runtimeType.hashCode ^ mapPropsToHashCode([user, tokens]);

  factory LoginResponse.fromJson(Map<String, dynamic> json) =>
      _$LoginResponseFromJson(json);

  Map<String, dynamic> toJson() => _$LoginResponseToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
