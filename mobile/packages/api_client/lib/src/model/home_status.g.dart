// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'home_status.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$HomeStatusCWProxy {
  HomeStatus label(String label);

  HomeStatus tone(HomeTone tone);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `HomeStatus(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// HomeStatus(...).copyWith(id: 12, name: "My name")
  /// ````
  HomeStatus call({String label, HomeTone tone});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfHomeStatus.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfHomeStatus.copyWith.fieldName(...)`
class _$HomeStatusCWProxyImpl implements _$HomeStatusCWProxy {
  const _$HomeStatusCWProxyImpl(this._value);

  final HomeStatus _value;

  @override
  HomeStatus label(String label) => this(label: label);

  @override
  HomeStatus tone(HomeTone tone) => this(tone: tone);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `HomeStatus(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// HomeStatus(...).copyWith(id: 12, name: "My name")
  /// ````
  HomeStatus call({
    Object? label = const $CopyWithPlaceholder(),
    Object? tone = const $CopyWithPlaceholder(),
  }) {
    return HomeStatus(
      label: label == const $CopyWithPlaceholder()
          ? _value.label
          // ignore: cast_nullable_to_non_nullable
          : label as String,
      tone: tone == const $CopyWithPlaceholder()
          ? _value.tone
          // ignore: cast_nullable_to_non_nullable
          : tone as HomeTone,
    );
  }
}

extension $HomeStatusCopyWith on HomeStatus {
  /// Returns a callable class that can be used as follows: `instanceOfHomeStatus.copyWith(...)` or like so:`instanceOfHomeStatus.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$HomeStatusCWProxy get copyWith => _$HomeStatusCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

HomeStatus _$HomeStatusFromJson(Map<String, dynamic> json) =>
    $checkedCreate('HomeStatus', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['label', 'tone']);
      final val = HomeStatus(
        label: $checkedConvert('label', (v) => v as String),
        tone: $checkedConvert('tone', (v) => $enumDecode(_$HomeToneEnumMap, v)),
      );
      return val;
    });

Map<String, dynamic> _$HomeStatusToJson(HomeStatus instance) =>
    <String, dynamic>{
      'label': instance.label,
      'tone': _$HomeToneEnumMap[instance.tone]!,
    };

const _$HomeToneEnumMap = {
  HomeTone.success: 'success',
  HomeTone.warning: 'warning',
  HomeTone.danger: 'danger',
  HomeTone.neutral: 'neutral',
  HomeTone.live: 'live',
  HomeTone.empty: 'empty',
};
