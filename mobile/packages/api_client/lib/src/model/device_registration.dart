//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'device_registration.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class DeviceRegistration {
  /// Returns a new [DeviceRegistration] instance.
  DeviceRegistration({required this.token, required this.platform});

  /// The FCM registration token.
  @JsonKey(name: r'token', required: true, includeIfNull: false)
  final String token;

  /// iOS joins later, with an APNs key.
  @JsonKey(name: r'platform', required: true, includeIfNull: false)
  final DeviceRegistrationPlatformEnum platform;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is DeviceRegistration &&
            runtimeType == other.runtimeType &&
            equals([token, platform], [other.token, other.platform]);
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^ mapPropsToHashCode([token, platform]);

  factory DeviceRegistration.fromJson(Map<String, dynamic> json) =>
      _$DeviceRegistrationFromJson(json);

  Map<String, dynamic> toJson() => _$DeviceRegistrationToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

/// iOS joins later, with an APNs key.
enum DeviceRegistrationPlatformEnum {
  @JsonValue(r'android')
  android(r'android');

  const DeviceRegistrationPlatformEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
