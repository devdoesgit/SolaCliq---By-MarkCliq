// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'home_summary_headline.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$HomeSummaryHeadlineCWProxy {
  HomeSummaryHeadline value(String value);

  HomeSummaryHeadline label(String label);

  HomeSummaryHeadline detail(String? detail);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `HomeSummaryHeadline(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// HomeSummaryHeadline(...).copyWith(id: 12, name: "My name")
  /// ````
  HomeSummaryHeadline call({String value, String label, String? detail});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfHomeSummaryHeadline.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfHomeSummaryHeadline.copyWith.fieldName(...)`
class _$HomeSummaryHeadlineCWProxyImpl implements _$HomeSummaryHeadlineCWProxy {
  const _$HomeSummaryHeadlineCWProxyImpl(this._value);

  final HomeSummaryHeadline _value;

  @override
  HomeSummaryHeadline value(String value) => this(value: value);

  @override
  HomeSummaryHeadline label(String label) => this(label: label);

  @override
  HomeSummaryHeadline detail(String? detail) => this(detail: detail);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `HomeSummaryHeadline(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// HomeSummaryHeadline(...).copyWith(id: 12, name: "My name")
  /// ````
  HomeSummaryHeadline call({
    Object? value = const $CopyWithPlaceholder(),
    Object? label = const $CopyWithPlaceholder(),
    Object? detail = const $CopyWithPlaceholder(),
  }) {
    return HomeSummaryHeadline(
      value: value == const $CopyWithPlaceholder()
          ? _value.value
          // ignore: cast_nullable_to_non_nullable
          : value as String,
      label: label == const $CopyWithPlaceholder()
          ? _value.label
          // ignore: cast_nullable_to_non_nullable
          : label as String,
      detail: detail == const $CopyWithPlaceholder()
          ? _value.detail
          // ignore: cast_nullable_to_non_nullable
          : detail as String?,
    );
  }
}

extension $HomeSummaryHeadlineCopyWith on HomeSummaryHeadline {
  /// Returns a callable class that can be used as follows: `instanceOfHomeSummaryHeadline.copyWith(...)` or like so:`instanceOfHomeSummaryHeadline.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$HomeSummaryHeadlineCWProxy get copyWith =>
      _$HomeSummaryHeadlineCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

HomeSummaryHeadline _$HomeSummaryHeadlineFromJson(Map<String, dynamic> json) =>
    $checkedCreate('HomeSummaryHeadline', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['value', 'label']);
      final val = HomeSummaryHeadline(
        value: $checkedConvert('value', (v) => v as String),
        label: $checkedConvert('label', (v) => v as String),
        detail: $checkedConvert('detail', (v) => v as String?),
      );
      return val;
    });

Map<String, dynamic> _$HomeSummaryHeadlineToJson(
  HomeSummaryHeadline instance,
) => <String, dynamic>{
  'value': instance.value,
  'label': instance.label,
  'detail': ?instance.detail,
};
