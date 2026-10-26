// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$SettingsCWProxy {
  Settings push(bool push);

  Settings whatsapp(bool whatsapp);

  Settings sound(bool sound);

  Settings language(SettingsLanguageEnum language);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `Settings(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// Settings(...).copyWith(id: 12, name: "My name")
  /// ````
  Settings call({
    bool push,
    bool whatsapp,
    bool sound,
    SettingsLanguageEnum language,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfSettings.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfSettings.copyWith.fieldName(...)`
class _$SettingsCWProxyImpl implements _$SettingsCWProxy {
  const _$SettingsCWProxyImpl(this._value);

  final Settings _value;

  @override
  Settings push(bool push) => this(push: push);

  @override
  Settings whatsapp(bool whatsapp) => this(whatsapp: whatsapp);

  @override
  Settings sound(bool sound) => this(sound: sound);

  @override
  Settings language(SettingsLanguageEnum language) => this(language: language);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `Settings(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// Settings(...).copyWith(id: 12, name: "My name")
  /// ````
  Settings call({
    Object? push = const $CopyWithPlaceholder(),
    Object? whatsapp = const $CopyWithPlaceholder(),
    Object? sound = const $CopyWithPlaceholder(),
    Object? language = const $CopyWithPlaceholder(),
  }) {
    return Settings(
      push: push == const $CopyWithPlaceholder()
          ? _value.push
          // ignore: cast_nullable_to_non_nullable
          : push as bool,
      whatsapp: whatsapp == const $CopyWithPlaceholder()
          ? _value.whatsapp
          // ignore: cast_nullable_to_non_nullable
          : whatsapp as bool,
      sound: sound == const $CopyWithPlaceholder()
          ? _value.sound
          // ignore: cast_nullable_to_non_nullable
          : sound as bool,
      language: language == const $CopyWithPlaceholder()
          ? _value.language
          // ignore: cast_nullable_to_non_nullable
          : language as SettingsLanguageEnum,
    );
  }
}

extension $SettingsCopyWith on Settings {
  /// Returns a callable class that can be used as follows: `instanceOfSettings.copyWith(...)` or like so:`instanceOfSettings.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$SettingsCWProxy get copyWith => _$SettingsCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Settings _$SettingsFromJson(Map<String, dynamic> json) =>
    $checkedCreate('Settings', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const ['push', 'whatsapp', 'sound', 'language'],
      );
      final val = Settings(
        push: $checkedConvert('push', (v) => v as bool),
        whatsapp: $checkedConvert('whatsapp', (v) => v as bool),
        sound: $checkedConvert('sound', (v) => v as bool),
        language: $checkedConvert(
          'language',
          (v) => $enumDecode(_$SettingsLanguageEnumEnumMap, v),
        ),
      );
      return val;
    });

Map<String, dynamic> _$SettingsToJson(Settings instance) => <String, dynamic>{
  'push': instance.push,
  'whatsapp': instance.whatsapp,
  'sound': instance.sound,
  'language': _$SettingsLanguageEnumEnumMap[instance.language]!,
};

const _$SettingsLanguageEnumEnumMap = {
  SettingsLanguageEnum.en: 'en',
  SettingsLanguageEnum.hi: 'hi',
  SettingsLanguageEnum.pa: 'pa',
};
