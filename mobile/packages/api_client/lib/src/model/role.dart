//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

enum Role {
  @JsonValue(r'org_admin')
  orgAdmin(r'org_admin'),
  @JsonValue(r'worker')
  worker(r'worker'),
  @JsonValue(r'agent')
  agent(r'agent');

  const Role(this.value);

  final String value;

  @override
  String toString() => value;
}
