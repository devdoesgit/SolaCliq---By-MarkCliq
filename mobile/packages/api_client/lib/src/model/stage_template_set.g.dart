// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stage_template_set.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$StageTemplateSetCWProxy {
  StageTemplateSet name(String name);

  StageTemplateSet checklist(List<String> checklist);

  StageTemplateSet photos(List<String> photos);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `StageTemplateSet(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// StageTemplateSet(...).copyWith(id: 12, name: "My name")
  /// ````
  StageTemplateSet call({
    String name,
    List<String> checklist,
    List<String> photos,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfStageTemplateSet.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfStageTemplateSet.copyWith.fieldName(...)`
class _$StageTemplateSetCWProxyImpl implements _$StageTemplateSetCWProxy {
  const _$StageTemplateSetCWProxyImpl(this._value);

  final StageTemplateSet _value;

  @override
  StageTemplateSet name(String name) => this(name: name);

  @override
  StageTemplateSet checklist(List<String> checklist) =>
      this(checklist: checklist);

  @override
  StageTemplateSet photos(List<String> photos) => this(photos: photos);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `StageTemplateSet(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// StageTemplateSet(...).copyWith(id: 12, name: "My name")
  /// ````
  StageTemplateSet call({
    Object? name = const $CopyWithPlaceholder(),
    Object? checklist = const $CopyWithPlaceholder(),
    Object? photos = const $CopyWithPlaceholder(),
  }) {
    return StageTemplateSet(
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

extension $StageTemplateSetCopyWith on StageTemplateSet {
  /// Returns a callable class that can be used as follows: `instanceOfStageTemplateSet.copyWith(...)` or like so:`instanceOfStageTemplateSet.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$StageTemplateSetCWProxy get copyWith => _$StageTemplateSetCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StageTemplateSet _$StageTemplateSetFromJson(Map<String, dynamic> json) =>
    $checkedCreate('StageTemplateSet', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['name', 'checklist', 'photos']);
      final val = StageTemplateSet(
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

Map<String, dynamic> _$StageTemplateSetToJson(StageTemplateSet instance) =>
    <String, dynamic>{
      'name': instance.name,
      'checklist': instance.checklist,
      'photos': instance.photos,
    };
