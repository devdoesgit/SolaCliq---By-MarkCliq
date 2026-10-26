// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'home_tile.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$HomeTileCWProxy {
  HomeTile label(String label);

  HomeTile value(String value);

  HomeTile icon(HomeTileIconEnum? icon);

  HomeTile footer(String? footer);

  HomeTile dark(bool? dark);

  HomeTile avatars(List<HomeVisual>? avatars);

  HomeTile action(String? action);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `HomeTile(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// HomeTile(...).copyWith(id: 12, name: "My name")
  /// ````
  HomeTile call({
    String label,
    String value,
    HomeTileIconEnum? icon,
    String? footer,
    bool? dark,
    List<HomeVisual>? avatars,
    String? action,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfHomeTile.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfHomeTile.copyWith.fieldName(...)`
class _$HomeTileCWProxyImpl implements _$HomeTileCWProxy {
  const _$HomeTileCWProxyImpl(this._value);

  final HomeTile _value;

  @override
  HomeTile label(String label) => this(label: label);

  @override
  HomeTile value(String value) => this(value: value);

  @override
  HomeTile icon(HomeTileIconEnum? icon) => this(icon: icon);

  @override
  HomeTile footer(String? footer) => this(footer: footer);

  @override
  HomeTile dark(bool? dark) => this(dark: dark);

  @override
  HomeTile avatars(List<HomeVisual>? avatars) => this(avatars: avatars);

  @override
  HomeTile action(String? action) => this(action: action);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `HomeTile(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// HomeTile(...).copyWith(id: 12, name: "My name")
  /// ````
  HomeTile call({
    Object? label = const $CopyWithPlaceholder(),
    Object? value = const $CopyWithPlaceholder(),
    Object? icon = const $CopyWithPlaceholder(),
    Object? footer = const $CopyWithPlaceholder(),
    Object? dark = const $CopyWithPlaceholder(),
    Object? avatars = const $CopyWithPlaceholder(),
    Object? action = const $CopyWithPlaceholder(),
  }) {
    return HomeTile(
      label: label == const $CopyWithPlaceholder()
          ? _value.label
          // ignore: cast_nullable_to_non_nullable
          : label as String,
      value: value == const $CopyWithPlaceholder()
          ? _value.value
          // ignore: cast_nullable_to_non_nullable
          : value as String,
      icon: icon == const $CopyWithPlaceholder()
          ? _value.icon
          // ignore: cast_nullable_to_non_nullable
          : icon as HomeTileIconEnum?,
      footer: footer == const $CopyWithPlaceholder()
          ? _value.footer
          // ignore: cast_nullable_to_non_nullable
          : footer as String?,
      dark: dark == const $CopyWithPlaceholder()
          ? _value.dark
          // ignore: cast_nullable_to_non_nullable
          : dark as bool?,
      avatars: avatars == const $CopyWithPlaceholder()
          ? _value.avatars
          // ignore: cast_nullable_to_non_nullable
          : avatars as List<HomeVisual>?,
      action: action == const $CopyWithPlaceholder()
          ? _value.action
          // ignore: cast_nullable_to_non_nullable
          : action as String?,
    );
  }
}

extension $HomeTileCopyWith on HomeTile {
  /// Returns a callable class that can be used as follows: `instanceOfHomeTile.copyWith(...)` or like so:`instanceOfHomeTile.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$HomeTileCWProxy get copyWith => _$HomeTileCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

HomeTile _$HomeTileFromJson(Map<String, dynamic> json) =>
    $checkedCreate('HomeTile', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['label', 'value']);
      final val = HomeTile(
        label: $checkedConvert('label', (v) => v as String),
        value: $checkedConvert('value', (v) => v as String),
        icon: $checkedConvert(
          'icon',
          (v) => $enumDecodeNullable(_$HomeTileIconEnumEnumMap, v),
        ),
        footer: $checkedConvert('footer', (v) => v as String?),
        dark: $checkedConvert('dark', (v) => v as bool? ?? false),
        avatars: $checkedConvert(
          'avatars',
          (v) => (v as List<dynamic>?)
              ?.map((e) => HomeVisual.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
        action: $checkedConvert('action', (v) => v as String?),
      );
      return val;
    });

Map<String, dynamic> _$HomeTileToJson(HomeTile instance) => <String, dynamic>{
  'label': instance.label,
  'value': instance.value,
  'icon': ?_$HomeTileIconEnumEnumMap[instance.icon],
  'footer': ?instance.footer,
  'dark': ?instance.dark,
  'avatars': ?instance.avatars?.map((e) => e.toJson()).toList(),
  'action': ?instance.action,
};

const _$HomeTileIconEnumEnumMap = {
  HomeTileIconEnum.camera: 'camera',
  HomeTileIconEnum.receipt: 'receipt',
  HomeTileIconEnum.alarm: 'alarm',
  HomeTileIconEnum.hourglass: 'hourglass',
  HomeTileIconEnum.shield: 'shield',
  HomeTileIconEnum.wallet: 'wallet',
  HomeTileIconEnum.sun: 'sun',
  HomeTileIconEnum.users: 'users',
};
