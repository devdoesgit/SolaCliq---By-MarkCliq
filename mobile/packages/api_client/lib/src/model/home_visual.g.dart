// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'home_visual.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$HomeVisualCWProxy {
  HomeVisual image(String? image);

  HomeVisual initials(String? initials);

  HomeVisual glyph(HomeVisualGlyphEnum? glyph);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `HomeVisual(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// HomeVisual(...).copyWith(id: 12, name: "My name")
  /// ````
  HomeVisual call({
    String? image,
    String? initials,
    HomeVisualGlyphEnum? glyph,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfHomeVisual.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfHomeVisual.copyWith.fieldName(...)`
class _$HomeVisualCWProxyImpl implements _$HomeVisualCWProxy {
  const _$HomeVisualCWProxyImpl(this._value);

  final HomeVisual _value;

  @override
  HomeVisual image(String? image) => this(image: image);

  @override
  HomeVisual initials(String? initials) => this(initials: initials);

  @override
  HomeVisual glyph(HomeVisualGlyphEnum? glyph) => this(glyph: glyph);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `HomeVisual(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// HomeVisual(...).copyWith(id: 12, name: "My name")
  /// ````
  HomeVisual call({
    Object? image = const $CopyWithPlaceholder(),
    Object? initials = const $CopyWithPlaceholder(),
    Object? glyph = const $CopyWithPlaceholder(),
  }) {
    return HomeVisual(
      image: image == const $CopyWithPlaceholder()
          ? _value.image
          // ignore: cast_nullable_to_non_nullable
          : image as String?,
      initials: initials == const $CopyWithPlaceholder()
          ? _value.initials
          // ignore: cast_nullable_to_non_nullable
          : initials as String?,
      glyph: glyph == const $CopyWithPlaceholder()
          ? _value.glyph
          // ignore: cast_nullable_to_non_nullable
          : glyph as HomeVisualGlyphEnum?,
    );
  }
}

extension $HomeVisualCopyWith on HomeVisual {
  /// Returns a callable class that can be used as follows: `instanceOfHomeVisual.copyWith(...)` or like so:`instanceOfHomeVisual.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$HomeVisualCWProxy get copyWith => _$HomeVisualCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

HomeVisual _$HomeVisualFromJson(Map<String, dynamic> json) =>
    $checkedCreate('HomeVisual', json, ($checkedConvert) {
      final val = HomeVisual(
        image: $checkedConvert('image', (v) => v as String?),
        initials: $checkedConvert('initials', (v) => v as String?),
        glyph: $checkedConvert(
          'glyph',
          (v) => $enumDecodeNullable(_$HomeVisualGlyphEnumEnumMap, v),
        ),
      );
      return val;
    });

Map<String, dynamic> _$HomeVisualToJson(HomeVisual instance) =>
    <String, dynamic>{
      'image': ?instance.image,
      'initials': ?instance.initials,
      'glyph': ?_$HomeVisualGlyphEnumEnumMap[instance.glyph],
    };

const _$HomeVisualGlyphEnumEnumMap = {
  HomeVisualGlyphEnum.card: 'card',
  HomeVisualGlyphEnum.bill: 'bill',
  HomeVisualGlyphEnum.passbook: 'passbook',
  HomeVisualGlyphEnum.rupee: 'rupee',
};
