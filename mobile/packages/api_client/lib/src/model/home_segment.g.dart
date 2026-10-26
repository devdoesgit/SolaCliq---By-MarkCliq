// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'home_segment.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$HomeSegmentCWProxy {
  HomeSegment weight(int weight);

  HomeSegment tone(HomeTone tone);

  HomeSegment label(String? label);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `HomeSegment(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// HomeSegment(...).copyWith(id: 12, name: "My name")
  /// ````
  HomeSegment call({int weight, HomeTone tone, String? label});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfHomeSegment.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfHomeSegment.copyWith.fieldName(...)`
class _$HomeSegmentCWProxyImpl implements _$HomeSegmentCWProxy {
  const _$HomeSegmentCWProxyImpl(this._value);

  final HomeSegment _value;

  @override
  HomeSegment weight(int weight) => this(weight: weight);

  @override
  HomeSegment tone(HomeTone tone) => this(tone: tone);

  @override
  HomeSegment label(String? label) => this(label: label);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `HomeSegment(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// HomeSegment(...).copyWith(id: 12, name: "My name")
  /// ````
  HomeSegment call({
    Object? weight = const $CopyWithPlaceholder(),
    Object? tone = const $CopyWithPlaceholder(),
    Object? label = const $CopyWithPlaceholder(),
  }) {
    return HomeSegment(
      weight: weight == const $CopyWithPlaceholder()
          ? _value.weight
          // ignore: cast_nullable_to_non_nullable
          : weight as int,
      tone: tone == const $CopyWithPlaceholder()
          ? _value.tone
          // ignore: cast_nullable_to_non_nullable
          : tone as HomeTone,
      label: label == const $CopyWithPlaceholder()
          ? _value.label
          // ignore: cast_nullable_to_non_nullable
          : label as String?,
    );
  }
}

extension $HomeSegmentCopyWith on HomeSegment {
  /// Returns a callable class that can be used as follows: `instanceOfHomeSegment.copyWith(...)` or like so:`instanceOfHomeSegment.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$HomeSegmentCWProxy get copyWith => _$HomeSegmentCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

HomeSegment _$HomeSegmentFromJson(Map<String, dynamic> json) =>
    $checkedCreate('HomeSegment', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['weight', 'tone']);
      final val = HomeSegment(
        weight: $checkedConvert('weight', (v) => (v as num).toInt()),
        tone: $checkedConvert('tone', (v) => $enumDecode(_$HomeToneEnumMap, v)),
        label: $checkedConvert('label', (v) => v as String?),
      );
      return val;
    });

Map<String, dynamic> _$HomeSegmentToJson(HomeSegment instance) =>
    <String, dynamic>{
      'weight': instance.weight,
      'tone': _$HomeToneEnumMap[instance.tone]!,
      'label': ?instance.label,
    };

const _$HomeToneEnumMap = {
  HomeTone.success: 'success',
  HomeTone.warning: 'warning',
  HomeTone.danger: 'danger',
  HomeTone.neutral: 'neutral',
  HomeTone.live: 'live',
  HomeTone.empty: 'empty',
};
