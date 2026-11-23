// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stage_set.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$StageSetCWProxy {
  StageSet stageIndex(int stageIndex);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `StageSet(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// StageSet(...).copyWith(id: 12, name: "My name")
  /// ````
  StageSet call({int stageIndex});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfStageSet.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfStageSet.copyWith.fieldName(...)`
class _$StageSetCWProxyImpl implements _$StageSetCWProxy {
  const _$StageSetCWProxyImpl(this._value);

  final StageSet _value;

  @override
  StageSet stageIndex(int stageIndex) => this(stageIndex: stageIndex);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `StageSet(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// StageSet(...).copyWith(id: 12, name: "My name")
  /// ````
  StageSet call({Object? stageIndex = const $CopyWithPlaceholder()}) {
    return StageSet(
      stageIndex: stageIndex == const $CopyWithPlaceholder()
          ? _value.stageIndex
          // ignore: cast_nullable_to_non_nullable
          : stageIndex as int,
    );
  }
}

extension $StageSetCopyWith on StageSet {
  /// Returns a callable class that can be used as follows: `instanceOfStageSet.copyWith(...)` or like so:`instanceOfStageSet.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$StageSetCWProxy get copyWith => _$StageSetCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StageSet _$StageSetFromJson(Map<String, dynamic> json) =>
    $checkedCreate('StageSet', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['stage_index']);
      final val = StageSet(
        stageIndex: $checkedConvert('stage_index', (v) => (v as num).toInt()),
      );
      return val;
    }, fieldKeyMap: const {'stageIndex': 'stage_index'});

Map<String, dynamic> _$StageSetToJson(StageSet instance) => <String, dynamic>{
  'stage_index': instance.stageIndex,
};
