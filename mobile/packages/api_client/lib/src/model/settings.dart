//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'settings.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class Settings {
  /// Returns a new [Settings] instance.
  Settings({required this.push, required this.whatsapp, required this.sound});

  /// Push notifications for new work, approvals and returns.
  @JsonKey(name: r'push', required: true, includeIfNull: false)
  final bool push;

  /// A daily WhatsApp summary at 8 pm.
  @JsonKey(name: r'whatsapp', required: true, includeIfNull: false)
  final bool whatsapp;

  @JsonKey(name: r'sound', required: true, includeIfNull: false)
  final bool sound;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is Settings &&
            runtimeType == other.runtimeType &&
            equals(
              [push, whatsapp, sound],
              [other.push, other.whatsapp, other.sound],
            );
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^ mapPropsToHashCode([push, whatsapp, sound]);

  factory Settings.fromJson(Map<String, dynamic> json) =>
      _$SettingsFromJson(json);

  Map<String, dynamic> toJson() => _$SettingsToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
