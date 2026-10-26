// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'home_progress.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$HomeProgressCWProxy {
  HomeProgress label(String label);

  HomeProgress trailing(String? trailing);

  HomeProgress segments(List<HomeSegment> segments);

  HomeProgress stages(List<String>? stages);

  HomeProgress legend(bool? legend);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `HomeProgress(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// HomeProgress(...).copyWith(id: 12, name: "My name")
  /// ````
  HomeProgress call({
    String label,
    String? trailing,
    List<HomeSegment> segments,
    List<String>? stages,
    bool? legend,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfHomeProgress.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfHomeProgress.copyWith.fieldName(...)`
class _$HomeProgressCWProxyImpl implements _$HomeProgressCWProxy {
  const _$HomeProgressCWProxyImpl(this._value);

  final HomeProgress _value;

  @override
  HomeProgress label(String label) => this(label: label);

  @override
  HomeProgress trailing(String? trailing) => this(trailing: trailing);

  @override
  HomeProgress segments(List<HomeSegment> segments) => this(segments: segments);

  @override
  HomeProgress stages(List<String>? stages) => this(stages: stages);

  @override
  HomeProgress legend(bool? legend) => this(legend: legend);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `HomeProgress(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// HomeProgress(...).copyWith(id: 12, name: "My name")
  /// ````
  HomeProgress call({
    Object? label = const $CopyWithPlaceholder(),
    Object? trailing = const $CopyWithPlaceholder(),
    Object? segments = const $CopyWithPlaceholder(),
    Object? stages = const $CopyWithPlaceholder(),
    Object? legend = const $CopyWithPlaceholder(),
  }) {
    return HomeProgress(
      label: label == const $CopyWithPlaceholder()
          ? _value.label
          // ignore: cast_nullable_to_non_nullable
          : label as String,
      trailing: trailing == const $CopyWithPlaceholder()
          ? _value.trailing
          // ignore: cast_nullable_to_non_nullable
          : trailing as String?,
      segments: segments == const $CopyWithPlaceholder()
          ? _value.segments
          // ignore: cast_nullable_to_non_nullable
          : segments as List<HomeSegment>,
      stages: stages == const $CopyWithPlaceholder()
          ? _value.stages
          // ignore: cast_nullable_to_non_nullable
          : stages as List<String>?,
      legend: legend == const $CopyWithPlaceholder()
          ? _value.legend
          // ignore: cast_nullable_to_non_nullable
          : legend as bool?,
    );
  }
}

extension $HomeProgressCopyWith on HomeProgress {
  /// Returns a callable class that can be used as follows: `instanceOfHomeProgress.copyWith(...)` or like so:`instanceOfHomeProgress.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$HomeProgressCWProxy get copyWith => _$HomeProgressCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

HomeProgress _$HomeProgressFromJson(Map<String, dynamic> json) =>
    $checkedCreate('HomeProgress', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['label', 'segments']);
      final val = HomeProgress(
        label: $checkedConvert('label', (v) => v as String),
        trailing: $checkedConvert('trailing', (v) => v as String?),
        segments: $checkedConvert(
          'segments',
          (v) => (v as List<dynamic>)
              .map((e) => HomeSegment.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
        stages: $checkedConvert(
          'stages',
          (v) => (v as List<dynamic>?)?.map((e) => e as String).toList(),
        ),
        legend: $checkedConvert('legend', (v) => v as bool? ?? false),
      );
      return val;
    });

Map<String, dynamic> _$HomeProgressToJson(HomeProgress instance) =>
    <String, dynamic>{
      'label': instance.label,
      'trailing': ?instance.trailing,
      'segments': instance.segments.map((e) => e.toJson()).toList(),
      'stages': ?instance.stages,
      'legend': ?instance.legend,
    };
