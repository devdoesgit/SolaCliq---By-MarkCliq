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
  Settings({
    required this.push,

    required this.whatsapp,

    required this.sound,

    required this.language,
  });

  /// Push notifications for new work, approvals and returns.
  @JsonKey(name: r'push', required: true, includeIfNull: false)
  final bool push;

  /// A daily WhatsApp summary at 8 pm.
  @JsonKey(name: r'whatsapp', required: true, includeIfNull: false)
  final bool whatsapp;

  @JsonKey(name: r'sound', required: true, includeIfNull: false)
  final bool sound;

  @JsonKey(name: r'language', required: true, includeIfNull: false)
  final SettingsLanguageEnum language;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is Settings &&
            runtimeType == other.runtimeType &&
            equals(
              [push, whatsapp, sound, language],
              [other.push, other.whatsapp, other.sound, other.language],
            );
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^
      mapPropsToHashCode([push, whatsapp, sound, language]);

  factory Settings.fromJson(Map<String, dynamic> json) =>
      _$SettingsFromJson(json);

  Map<String, dynamic> toJson() => _$SettingsToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum SettingsLanguageEnum {
  @JsonValue(r'en')
  en(r'en'),
  @JsonValue(r'hi')
  hi(r'hi'),
  @JsonValue(r'pa')
  pa(r'pa');

  const SettingsLanguageEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
