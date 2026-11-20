//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'terms_status.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class TermsStatus {
  /// Returns a new [TermsStatus] instance.
  TermsStatus({this.acceptedVersion, required this.currentVersion});

  /// The latest version the person agreed to. Left out if they never have (an account someone else made for them).
  @JsonKey(name: r'accepted_version', required: false, includeIfNull: false)
  final int? acceptedVersion;

  /// The version in force. When it differs from `accepted_version`, the app shows the \"Before you start\" screen and nothing else until the person agrees (`POST /me/terms`) or logs out.
  @JsonKey(name: r'current_version', required: true, includeIfNull: false)
  final int currentVersion;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is TermsStatus &&
            runtimeType == other.runtimeType &&
            equals(
              [acceptedVersion, currentVersion],
              [other.acceptedVersion, other.currentVersion],
            );
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^
      mapPropsToHashCode([acceptedVersion, currentVersion]);

  factory TermsStatus.fromJson(Map<String, dynamic> json) =>
      _$TermsStatusFromJson(json);

  Map<String, dynamic> toJson() => _$TermsStatusToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
