// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stage.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$StageCWProxy {
  Stage index(int index);

  Stage name(String name);

  Stage checklist(List<String> checklist);

  Stage photos(List<String> photos);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `Stage(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// Stage(...).copyWith(id: 12, name: "My name")
  /// ````
  Stage call({
    int index,
    String name,
    List<String> checklist,
    List<String> photos,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfStage.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfStage.copyWith.fieldName(...)`
class _$StageCWProxyImpl implements _$StageCWProxy {
  const _$StageCWProxyImpl(this._value);

  final Stage _value;

  @override
  Stage index(int index) => this(index: index);

  @override
  Stage name(String name) => this(name: name);

  @override
  Stage checklist(List<String> checklist) => this(checklist: checklist);

  @override
  Stage photos(List<String> photos) => this(photos: photos);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `Stage(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// Stage(...).copyWith(id: 12, name: "My name")
  /// ````
  Stage call({
    Object? index = const $CopyWithPlaceholder(),
    Object? name = const $CopyWithPlaceholder(),
    Object? checklist = const $CopyWithPlaceholder(),
    Object? photos = const $CopyWithPlaceholder(),
  }) {
    return Stage(
      index: index == const $CopyWithPlaceholder()
          ? _value.index
          // ignore: cast_nullable_to_non_nullable
          : index as int,
      name: name == const $CopyWithPlaceholder()
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String,
      checklist: checklist == const $CopyWithPlaceholder()
          ? _value.checklist
          // ignore: cast_nullable_to_non_nullable
          : checklist as List<String>,
      photos: photos == const $CopyWithPlaceholder()
          ? _value.photos
          // ignore: cast_nullable_to_non_nullable
          : photos as List<String>,
    );
  }
}

extension $StageCopyWith on Stage {
  /// Returns a callable class that can be used as follows: `instanceOfStage.copyWith(...)` or like so:`instanceOfStage.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$StageCWProxy get copyWith => _$StageCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Stage _$StageFromJson(Map<String, dynamic> json) =>
    $checkedCreate('Stage', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const ['index', 'name', 'checklist', 'photos'],
      );
      final val = Stage(
        index: $checkedConvert('index', (v) => (v as num).toInt()),
        name: $checkedConvert('name', (v) => v as String),
        checklist: $checkedConvert(
          'checklist',
          (v) => (v as List<dynamic>).map((e) => e as String).toList(),
        ),
        photos: $checkedConvert(
          'photos',
          (v) => (v as List<dynamic>).map((e) => e as String).toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$StageToJson(Stage instance) => <String, dynamic>{
  'index': instance.index,
  'name': instance.name,
  'checklist': instance.checklist,
  'photos': instance.photos,
};
