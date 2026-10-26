// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'home_row.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$HomeRowCWProxy {
  HomeRow image(String? image);

  HomeRow initials(String? initials);

  HomeRow glyph(HomeRowGlyphEnum? glyph);

  HomeRow id(String id);

  HomeRow title(String title);

  HomeRow detail(String detail);

  HomeRow status(HomeStatus? status);

  HomeRow action(String? action);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `HomeRow(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// HomeRow(...).copyWith(id: 12, name: "My name")
  /// ````
  HomeRow call({
    String? image,
    String? initials,
    HomeRowGlyphEnum? glyph,
    String id,
    String title,
    String detail,
    HomeStatus? status,
    String? action,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfHomeRow.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfHomeRow.copyWith.fieldName(...)`
class _$HomeRowCWProxyImpl implements _$HomeRowCWProxy {
  const _$HomeRowCWProxyImpl(this._value);

  final HomeRow _value;

  @override
  HomeRow image(String? image) => this(image: image);

  @override
  HomeRow initials(String? initials) => this(initials: initials);

  @override
  HomeRow glyph(HomeRowGlyphEnum? glyph) => this(glyph: glyph);

  @override
  HomeRow id(String id) => this(id: id);

  @override
  HomeRow title(String title) => this(title: title);

  @override
  HomeRow detail(String detail) => this(detail: detail);

  @override
  HomeRow status(HomeStatus? status) => this(status: status);

  @override
  HomeRow action(String? action) => this(action: action);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `HomeRow(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// HomeRow(...).copyWith(id: 12, name: "My name")
  /// ````
  HomeRow call({
    Object? image = const $CopyWithPlaceholder(),
    Object? initials = const $CopyWithPlaceholder(),
    Object? glyph = const $CopyWithPlaceholder(),
    Object? id = const $CopyWithPlaceholder(),
    Object? title = const $CopyWithPlaceholder(),
    Object? detail = const $CopyWithPlaceholder(),
    Object? status = const $CopyWithPlaceholder(),
    Object? action = const $CopyWithPlaceholder(),
  }) {
    return HomeRow(
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
          : glyph as HomeRowGlyphEnum?,
      id: id == const $CopyWithPlaceholder()
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      title: title == const $CopyWithPlaceholder()
          ? _value.title
          // ignore: cast_nullable_to_non_nullable
          : title as String,
      detail: detail == const $CopyWithPlaceholder()
          ? _value.detail
          // ignore: cast_nullable_to_non_nullable
          : detail as String,
      status: status == const $CopyWithPlaceholder()
          ? _value.status
          // ignore: cast_nullable_to_non_nullable
          : status as HomeStatus?,
      action: action == const $CopyWithPlaceholder()
          ? _value.action
          // ignore: cast_nullable_to_non_nullable
          : action as String?,
    );
  }
}

extension $HomeRowCopyWith on HomeRow {
  /// Returns a callable class that can be used as follows: `instanceOfHomeRow.copyWith(...)` or like so:`instanceOfHomeRow.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$HomeRowCWProxy get copyWith => _$HomeRowCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

HomeRow _$HomeRowFromJson(Map<String, dynamic> json) =>
    $checkedCreate('HomeRow', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['id', 'title', 'detail']);
      final val = HomeRow(
        image: $checkedConvert('image', (v) => v as String?),
        initials: $checkedConvert('initials', (v) => v as String?),
        glyph: $checkedConvert(
          'glyph',
          (v) => $enumDecodeNullable(_$HomeRowGlyphEnumEnumMap, v),
        ),
        id: $checkedConvert('id', (v) => v as String),
        title: $checkedConvert('title', (v) => v as String),
        detail: $checkedConvert('detail', (v) => v as String),
        status: $checkedConvert(
          'status',
          (v) =>
              v == null ? null : HomeStatus.fromJson(v as Map<String, dynamic>),
        ),
        action: $checkedConvert('action', (v) => v as String?),
      );
      return val;
    });

Map<String, dynamic> _$HomeRowToJson(HomeRow instance) => <String, dynamic>{
  'image': ?instance.image,
  'initials': ?instance.initials,
  'glyph': ?_$HomeRowGlyphEnumEnumMap[instance.glyph],
  'id': instance.id,
  'title': instance.title,
  'detail': instance.detail,
  'status': ?instance.status?.toJson(),
  'action': ?instance.action,
};

const _$HomeRowGlyphEnumEnumMap = {
  HomeRowGlyphEnum.card: 'card',
  HomeRowGlyphEnum.bill: 'bill',
  HomeRowGlyphEnum.passbook: 'passbook',
  HomeRowGlyphEnum.rupee: 'rupee',
};
