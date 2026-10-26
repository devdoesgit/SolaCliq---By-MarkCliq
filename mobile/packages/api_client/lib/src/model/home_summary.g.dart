// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'home_summary.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$HomeSummaryCWProxy {
  HomeSummary unreadNotifications(int? unreadNotifications);

  HomeSummary eyebrow(String eyebrow);

  HomeSummary title(String title);

  HomeSummary headline(HomeSummaryHeadline? headline);

  HomeSummary week(List<HomeDay>? week);

  HomeSummary energy(HomeEnergy? energy);

  HomeSummary tiles(List<HomeTile> tiles);

  HomeSummary progress(HomeProgress? progress);

  HomeSummary list(HomeSummaryList list);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `HomeSummary(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// HomeSummary(...).copyWith(id: 12, name: "My name")
  /// ````
  HomeSummary call({
    int? unreadNotifications,
    String eyebrow,
    String title,
    HomeSummaryHeadline? headline,
    List<HomeDay>? week,
    HomeEnergy? energy,
    List<HomeTile> tiles,
    HomeProgress? progress,
    HomeSummaryList list,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfHomeSummary.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfHomeSummary.copyWith.fieldName(...)`
class _$HomeSummaryCWProxyImpl implements _$HomeSummaryCWProxy {
  const _$HomeSummaryCWProxyImpl(this._value);

  final HomeSummary _value;

  @override
  HomeSummary unreadNotifications(int? unreadNotifications) =>
      this(unreadNotifications: unreadNotifications);

  @override
  HomeSummary eyebrow(String eyebrow) => this(eyebrow: eyebrow);

  @override
  HomeSummary title(String title) => this(title: title);

  @override
  HomeSummary headline(HomeSummaryHeadline? headline) =>
      this(headline: headline);

  @override
  HomeSummary week(List<HomeDay>? week) => this(week: week);

  @override
  HomeSummary energy(HomeEnergy? energy) => this(energy: energy);

  @override
  HomeSummary tiles(List<HomeTile> tiles) => this(tiles: tiles);

  @override
  HomeSummary progress(HomeProgress? progress) => this(progress: progress);

  @override
  HomeSummary list(HomeSummaryList list) => this(list: list);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `HomeSummary(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// HomeSummary(...).copyWith(id: 12, name: "My name")
  /// ````
  HomeSummary call({
    Object? unreadNotifications = const $CopyWithPlaceholder(),
    Object? eyebrow = const $CopyWithPlaceholder(),
    Object? title = const $CopyWithPlaceholder(),
    Object? headline = const $CopyWithPlaceholder(),
    Object? week = const $CopyWithPlaceholder(),
    Object? energy = const $CopyWithPlaceholder(),
    Object? tiles = const $CopyWithPlaceholder(),
    Object? progress = const $CopyWithPlaceholder(),
    Object? list = const $CopyWithPlaceholder(),
  }) {
    return HomeSummary(
      unreadNotifications: unreadNotifications == const $CopyWithPlaceholder()
          ? _value.unreadNotifications
          // ignore: cast_nullable_to_non_nullable
          : unreadNotifications as int?,
      eyebrow: eyebrow == const $CopyWithPlaceholder()
          ? _value.eyebrow
          // ignore: cast_nullable_to_non_nullable
          : eyebrow as String,
      title: title == const $CopyWithPlaceholder()
          ? _value.title
          // ignore: cast_nullable_to_non_nullable
          : title as String,
      headline: headline == const $CopyWithPlaceholder()
          ? _value.headline
          // ignore: cast_nullable_to_non_nullable
          : headline as HomeSummaryHeadline?,
      week: week == const $CopyWithPlaceholder()
          ? _value.week
          // ignore: cast_nullable_to_non_nullable
          : week as List<HomeDay>?,
      energy: energy == const $CopyWithPlaceholder()
          ? _value.energy
          // ignore: cast_nullable_to_non_nullable
          : energy as HomeEnergy?,
      tiles: tiles == const $CopyWithPlaceholder()
          ? _value.tiles
          // ignore: cast_nullable_to_non_nullable
          : tiles as List<HomeTile>,
      progress: progress == const $CopyWithPlaceholder()
          ? _value.progress
          // ignore: cast_nullable_to_non_nullable
          : progress as HomeProgress?,
      list: list == const $CopyWithPlaceholder()
          ? _value.list
          // ignore: cast_nullable_to_non_nullable
          : list as HomeSummaryList,
    );
  }
}

extension $HomeSummaryCopyWith on HomeSummary {
  /// Returns a callable class that can be used as follows: `instanceOfHomeSummary.copyWith(...)` or like so:`instanceOfHomeSummary.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$HomeSummaryCWProxy get copyWith => _$HomeSummaryCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

HomeSummary _$HomeSummaryFromJson(Map<String, dynamic> json) => $checkedCreate(
  'HomeSummary',
  json,
  ($checkedConvert) {
    $checkKeys(json, requiredKeys: const ['eyebrow', 'title', 'tiles', 'list']);
    final val = HomeSummary(
      unreadNotifications: $checkedConvert(
        'unread_notifications',
        (v) => (v as num?)?.toInt(),
      ),
      eyebrow: $checkedConvert('eyebrow', (v) => v as String),
      title: $checkedConvert('title', (v) => v as String),
      headline: $checkedConvert(
        'headline',
        (v) => v == null
            ? null
            : HomeSummaryHeadline.fromJson(v as Map<String, dynamic>),
      ),
      week: $checkedConvert(
        'week',
        (v) => (v as List<dynamic>?)
            ?.map((e) => HomeDay.fromJson(e as Map<String, dynamic>))
            .toList(),
      ),
      energy: $checkedConvert(
        'energy',
        (v) =>
            v == null ? null : HomeEnergy.fromJson(v as Map<String, dynamic>),
      ),
      tiles: $checkedConvert(
        'tiles',
        (v) => (v as List<dynamic>)
            .map((e) => HomeTile.fromJson(e as Map<String, dynamic>))
            .toList(),
      ),
      progress: $checkedConvert(
        'progress',
        (v) =>
            v == null ? null : HomeProgress.fromJson(v as Map<String, dynamic>),
      ),
      list: $checkedConvert(
        'list',
        (v) => HomeSummaryList.fromJson(v as Map<String, dynamic>),
      ),
    );
    return val;
  },
  fieldKeyMap: const {'unreadNotifications': 'unread_notifications'},
);

Map<String, dynamic> _$HomeSummaryToJson(HomeSummary instance) =>
    <String, dynamic>{
      'unread_notifications': ?instance.unreadNotifications,
      'eyebrow': instance.eyebrow,
      'title': instance.title,
      'headline': ?instance.headline?.toJson(),
      'week': ?instance.week?.map((e) => e.toJson()).toList(),
      'energy': ?instance.energy?.toJson(),
      'tiles': instance.tiles.map((e) => e.toJson()).toList(),
      'progress': ?instance.progress?.toJson(),
      'list': instance.list.toJson(),
    };
