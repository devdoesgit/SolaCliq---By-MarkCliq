// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'home_energy.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$HomeEnergyCWProxy {
  HomeEnergy nowKw(num nowKw);

  HomeEnergy todayKwh(num todayKwh);

  HomeEnergy sunrise(String sunrise);

  HomeEnergy sunset(String sunset);

  HomeEnergy dayProgress(num dayProgress);

  HomeEnergy hours(List<num> hours);

  HomeEnergy nowIndex(int nowIndex);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `HomeEnergy(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// HomeEnergy(...).copyWith(id: 12, name: "My name")
  /// ````
  HomeEnergy call({
    num nowKw,
    num todayKwh,
    String sunrise,
    String sunset,
    num dayProgress,
    List<num> hours,
    int nowIndex,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfHomeEnergy.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfHomeEnergy.copyWith.fieldName(...)`
class _$HomeEnergyCWProxyImpl implements _$HomeEnergyCWProxy {
  const _$HomeEnergyCWProxyImpl(this._value);

  final HomeEnergy _value;

  @override
  HomeEnergy nowKw(num nowKw) => this(nowKw: nowKw);

  @override
  HomeEnergy todayKwh(num todayKwh) => this(todayKwh: todayKwh);

  @override
  HomeEnergy sunrise(String sunrise) => this(sunrise: sunrise);

  @override
  HomeEnergy sunset(String sunset) => this(sunset: sunset);

  @override
  HomeEnergy dayProgress(num dayProgress) => this(dayProgress: dayProgress);

  @override
  HomeEnergy hours(List<num> hours) => this(hours: hours);

  @override
  HomeEnergy nowIndex(int nowIndex) => this(nowIndex: nowIndex);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `HomeEnergy(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// HomeEnergy(...).copyWith(id: 12, name: "My name")
  /// ````
  HomeEnergy call({
    Object? nowKw = const $CopyWithPlaceholder(),
    Object? todayKwh = const $CopyWithPlaceholder(),
    Object? sunrise = const $CopyWithPlaceholder(),
    Object? sunset = const $CopyWithPlaceholder(),
    Object? dayProgress = const $CopyWithPlaceholder(),
    Object? hours = const $CopyWithPlaceholder(),
    Object? nowIndex = const $CopyWithPlaceholder(),
  }) {
    return HomeEnergy(
      nowKw: nowKw == const $CopyWithPlaceholder()
          ? _value.nowKw
          // ignore: cast_nullable_to_non_nullable
          : nowKw as num,
      todayKwh: todayKwh == const $CopyWithPlaceholder()
          ? _value.todayKwh
          // ignore: cast_nullable_to_non_nullable
          : todayKwh as num,
      sunrise: sunrise == const $CopyWithPlaceholder()
          ? _value.sunrise
          // ignore: cast_nullable_to_non_nullable
          : sunrise as String,
      sunset: sunset == const $CopyWithPlaceholder()
          ? _value.sunset
          // ignore: cast_nullable_to_non_nullable
          : sunset as String,
      dayProgress: dayProgress == const $CopyWithPlaceholder()
          ? _value.dayProgress
          // ignore: cast_nullable_to_non_nullable
          : dayProgress as num,
      hours: hours == const $CopyWithPlaceholder()
          ? _value.hours
          // ignore: cast_nullable_to_non_nullable
          : hours as List<num>,
      nowIndex: nowIndex == const $CopyWithPlaceholder()
          ? _value.nowIndex
          // ignore: cast_nullable_to_non_nullable
          : nowIndex as int,
    );
  }
}

extension $HomeEnergyCopyWith on HomeEnergy {
  /// Returns a callable class that can be used as follows: `instanceOfHomeEnergy.copyWith(...)` or like so:`instanceOfHomeEnergy.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$HomeEnergyCWProxy get copyWith => _$HomeEnergyCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

HomeEnergy _$HomeEnergyFromJson(Map<String, dynamic> json) => $checkedCreate(
  'HomeEnergy',
  json,
  ($checkedConvert) {
    $checkKeys(
      json,
      requiredKeys: const [
        'now_kw',
        'today_kwh',
        'sunrise',
        'sunset',
        'day_progress',
        'hours',
        'now_index',
      ],
    );
    final val = HomeEnergy(
      nowKw: $checkedConvert('now_kw', (v) => v as num),
      todayKwh: $checkedConvert('today_kwh', (v) => v as num),
      sunrise: $checkedConvert('sunrise', (v) => v as String),
      sunset: $checkedConvert('sunset', (v) => v as String),
      dayProgress: $checkedConvert('day_progress', (v) => v as num),
      hours: $checkedConvert(
        'hours',
        (v) => (v as List<dynamic>).map((e) => e as num).toList(),
      ),
      nowIndex: $checkedConvert('now_index', (v) => (v as num).toInt()),
    );
    return val;
  },
  fieldKeyMap: const {
    'nowKw': 'now_kw',
    'todayKwh': 'today_kwh',
    'dayProgress': 'day_progress',
    'nowIndex': 'now_index',
  },
);

Map<String, dynamic> _$HomeEnergyToJson(HomeEnergy instance) =>
    <String, dynamic>{
      'now_kw': instance.nowKw,
      'today_kwh': instance.todayKwh,
      'sunrise': instance.sunrise,
      'sunset': instance.sunset,
      'day_progress': instance.dayProgress,
      'hours': instance.hours,
      'now_index': instance.nowIndex,
    };
