//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

/// `working`: started today in India, no end yet. `ended`: has an end. `no_check_out`: no end and its date has passed (a late end sent from offline can still end it).
enum AttendanceStatus {
  @JsonValue(r'working')
  working(r'working'),
  @JsonValue(r'ended')
  ended(r'ended'),
  @JsonValue(r'no_check_out')
  noCheckOut(r'no_check_out');

  const AttendanceStatus(this.value);

  final String value;

  @override
  String toString() => value;
}
