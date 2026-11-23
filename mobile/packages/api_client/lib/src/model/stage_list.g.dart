// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stage_list.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$StageListCWProxy {
  StageList stages(List<Stage> stages);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `StageList(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// StageList(...).copyWith(id: 12, name: "My name")
  /// ````
  StageList call({List<Stage> stages});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfStageList.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfStageList.copyWith.fieldName(...)`
class _$StageListCWProxyImpl implements _$StageListCWProxy {
  const _$StageListCWProxyImpl(this._value);

  final StageList _value;

  @override
  StageList stages(List<Stage> stages) => this(stages: stages);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `StageList(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// StageList(...).copyWith(id: 12, name: "My name")
  /// ````
  StageList call({Object? stages = const $CopyWithPlaceholder()}) {
    return StageList(
      stages: stages == const $CopyWithPlaceholder()
          ? _value.stages
          // ignore: cast_nullable_to_non_nullable
          : stages as List<Stage>,
    );
  }
}

extension $StageListCopyWith on StageList {
  /// Returns a callable class that can be used as follows: `instanceOfStageList.copyWith(...)` or like so:`instanceOfStageList.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$StageListCWProxy get copyWith => _$StageListCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StageList _$StageListFromJson(Map<String, dynamic> json) =>
    $checkedCreate('StageList', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['stages']);
      final val = StageList(
        stages: $checkedConvert(
          'stages',
          (v) => (v as List<dynamic>)
              .map((e) => Stage.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$StageListToJson(StageList instance) => <String, dynamic>{
  'stages': instance.stages.map((e) => e.toJson()).toList(),
};
