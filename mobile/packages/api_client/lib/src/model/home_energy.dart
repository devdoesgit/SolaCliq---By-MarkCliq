//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'home_energy.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class HomeEnergy {
  /// Returns a new [HomeEnergy] instance.
  HomeEnergy({
    required this.nowKw,

    required this.todayKwh,

    required this.sunrise,

    required this.sunset,

    required this.dayProgress,

    required this.hours,

    required this.nowIndex,
  });

  @JsonKey(name: r'now_kw', required: true, includeIfNull: false)
  final num nowKw;

  @JsonKey(name: r'today_kwh', required: true, includeIfNull: false)
  final num todayKwh;

  @JsonKey(name: r'sunrise', required: true, includeIfNull: false)
  final String sunrise;

  @JsonKey(name: r'sunset', required: true, includeIfNull: false)
  final String sunset;

  // minimum: 0
  // maximum: 1
  @JsonKey(name: r'day_progress', required: true, includeIfNull: false)
  final num dayProgress;

  /// kWh per daylight hour, from sunrise.
  @JsonKey(name: r'hours', required: true, includeIfNull: false)
  final List<num> hours;

  @JsonKey(name: r'now_index', required: true, includeIfNull: false)
  final int nowIndex;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is HomeEnergy &&
            runtimeType == other.runtimeType &&
            equals(
              [nowKw, todayKwh, sunrise, sunset, dayProgress, hours, nowIndex],
              [
                other.nowKw,
                other.todayKwh,
                other.sunrise,
                other.sunset,
                other.dayProgress,
                other.hours,
                other.nowIndex,
              ],
            );
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^
      mapPropsToHashCode([
        nowKw,
        todayKwh,
        sunrise,
        sunset,
        dayProgress,
        hours,
        nowIndex,
      ]);

  factory HomeEnergy.fromJson(Map<String, dynamic> json) =>
      _$HomeEnergyFromJson(json);

  Map<String, dynamic> toJson() => _$HomeEnergyToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
