//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

enum TaskProblemReason {
  @JsonValue(r'customer_away')
  customerAway(r'customer_away'),
  @JsonValue(r'material_missing')
  materialMissing(r'material_missing'),
  @JsonValue(r'bad_weather')
  badWeather(r'bad_weather'),
  @JsonValue(r'site_not_ready')
  siteNotReady(r'site_not_ready'),
  @JsonValue(r'safety')
  safety(r'safety'),
  @JsonValue(r'other')
  other(r'other');

  const TaskProblemReason(this.value);

  final String value;

  @override
  String toString() => value;
}
