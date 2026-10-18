//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

enum OrgStatus {
  @JsonValue(r'pending')
  pending(r'pending'),
  @JsonValue(r'active')
  active(r'active'),
  @JsonValue(r'suspended')
  suspended(r'suspended');

  const OrgStatus(this.value);

  final String value;

  @override
  String toString() => value;
}
