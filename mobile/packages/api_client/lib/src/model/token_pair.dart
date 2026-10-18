//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'token_pair.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class TokenPair {
  /// Returns a new [TokenPair] instance.
  TokenPair({
    required this.accessToken,

    required this.refreshToken,

    required this.accessExpiresIn,

    required this.tokenType,
  });

  @JsonKey(name: r'access_token', required: true, includeIfNull: false)
  final String accessToken;

  /// Single use; the next refresh returns a new one.
  @JsonKey(name: r'refresh_token', required: true, includeIfNull: false)
  final String refreshToken;

  /// Seconds until the access token expires.
  @JsonKey(name: r'access_expires_in', required: true, includeIfNull: false)
  final int accessExpiresIn;

  @JsonKey(name: r'token_type', required: true, includeIfNull: false)
  final TokenPairTokenTypeEnum tokenType;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is TokenPair &&
            runtimeType == other.runtimeType &&
            equals(
              [accessToken, refreshToken, accessExpiresIn, tokenType],
              [
                other.accessToken,
                other.refreshToken,
                other.accessExpiresIn,
                other.tokenType,
              ],
            );
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^
      mapPropsToHashCode([
        accessToken,
        refreshToken,
        accessExpiresIn,
        tokenType,
      ]);

  factory TokenPair.fromJson(Map<String, dynamic> json) =>
      _$TokenPairFromJson(json);

  Map<String, dynamic> toJson() => _$TokenPairToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum TokenPairTokenTypeEnum {
  @JsonValue(r'Bearer')
  bearer(r'Bearer');

  const TokenPairTokenTypeEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
