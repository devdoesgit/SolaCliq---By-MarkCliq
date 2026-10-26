// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'home_day.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$HomeDayCWProxy {
  HomeDay day(String day);

  HomeDay date(int date);

  HomeDay today(bool? today);

  HomeDay dots(List<HomeDayDotsEnum> dots);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `HomeDay(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// HomeDay(...).copyWith(id: 12, name: "My name")
  /// ````
  HomeDay call({String day, int date, bool? today, List<HomeDayDotsEnum> dots});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfHomeDay.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfHomeDay.copyWith.fieldName(...)`
class _$HomeDayCWProxyImpl implements _$HomeDayCWProxy {
  const _$HomeDayCWProxyImpl(this._value);

  final HomeDay _value;

  @override
  HomeDay day(String day) => this(day: day);

  @override
  HomeDay date(int date) => this(date: date);

  @override
  HomeDay today(bool? today) => this(today: today);

  @override
  HomeDay dots(List<HomeDayDotsEnum> dots) => this(dots: dots);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `HomeDay(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// HomeDay(...).copyWith(id: 12, name: "My name")
  /// ````
  HomeDay call({
    Object? day = const $CopyWithPlaceholder(),
    Object? date = const $CopyWithPlaceholder(),
    Object? today = const $CopyWithPlaceholder(),
    Object? dots = const $CopyWithPlaceholder(),
  }) {
    return HomeDay(
      day: day == const $CopyWithPlaceholder()
          ? _value.day
          // ignore: cast_nullable_to_non_nullable
          : day as String,
      date: date == const $CopyWithPlaceholder()
          ? _value.date
          // ignore: cast_nullable_to_non_nullable
          : date as int,
      today: today == const $CopyWithPlaceholder()
          ? _value.today
          // ignore: cast_nullable_to_non_nullable
          : today as bool?,
      dots: dots == const $CopyWithPlaceholder()
          ? _value.dots
          // ignore: cast_nullable_to_non_nullable
          : dots as List<HomeDayDotsEnum>,
    );
  }
}

extension $HomeDayCopyWith on HomeDay {
  /// Returns a callable class that can be used as follows: `instanceOfHomeDay.copyWith(...)` or like so:`instanceOfHomeDay.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$HomeDayCWProxy get copyWith => _$HomeDayCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

HomeDay _$HomeDayFromJson(Map<String, dynamic> json) =>
    $checkedCreate('HomeDay', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['day', 'date', 'dots']);
      final val = HomeDay(
        day: $checkedConvert('day', (v) => v as String),
        date: $checkedConvert('date', (v) => (v as num).toInt()),
        today: $checkedConvert('today', (v) => v as bool? ?? false),
        dots: $checkedConvert(
          'dots',
          (v) => (v as List<dynamic>)
              .map((e) => $enumDecode(_$HomeDayDotsEnumEnumMap, e))
              .toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$HomeDayToJson(HomeDay instance) => <String, dynamic>{
  'day': instance.day,
  'date': instance.date,
  'today': ?instance.today,
  'dots': instance.dots.map((e) => _$HomeDayDotsEnumEnumMap[e]!).toList(),
};

const _$HomeDayDotsEnumEnumMap = {
  HomeDayDotsEnum.done: 'done',
  HomeDayDotsEnum.live: 'live',
  HomeDayDotsEnum.planned: 'planned',
};
