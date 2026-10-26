//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

/// A status colour: success (done), warning (due), danger (needs a fix), neutral (waiting, booked), live (now, current), empty (to come).
enum HomeTone {
  @JsonValue(r'success')
  success(r'success'),
  @JsonValue(r'warning')
  warning(r'warning'),
  @JsonValue(r'danger')
  danger(r'danger'),
  @JsonValue(r'neutral')
  neutral(r'neutral'),
  @JsonValue(r'live')
  live(r'live'),
  @JsonValue(r'empty')
  empty(r'empty');

  const HomeTone(this.value);

  final String value;

  @override
  String toString() => value;
}
