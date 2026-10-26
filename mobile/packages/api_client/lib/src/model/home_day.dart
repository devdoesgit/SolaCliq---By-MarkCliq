//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'home_day.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class HomeDay {
  /// Returns a new [HomeDay] instance.
  HomeDay({
    required this.day,

    required this.date,

    this.today = false,

    required this.dots,
  });

  @JsonKey(name: r'day', required: true, includeIfNull: false)
  final String day;

  @JsonKey(name: r'date', required: true, includeIfNull: false)
  final int date;

  @JsonKey(
    defaultValue: false,
    name: r'today',
    required: false,
    includeIfNull: false,
  )
  final bool? today;

  @JsonKey(name: r'dots', required: true, includeIfNull: false)
  final List<HomeDayDotsEnum> dots;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is HomeDay &&
            runtimeType == other.runtimeType &&
            equals(
              [day, date, today, dots],
              [other.day, other.date, other.today, other.dots],
            );
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^ mapPropsToHashCode([day, date, today, dots]);

  factory HomeDay.fromJson(Map<String, dynamic> json) =>
      _$HomeDayFromJson(json);

  Map<String, dynamic> toJson() => _$HomeDayToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum HomeDayDotsEnum {
  @JsonValue(r'done')
  done(r'done'),
  @JsonValue(r'live')
  live(r'live'),
  @JsonValue(r'planned')
  planned(r'planned');

  const HomeDayDotsEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
