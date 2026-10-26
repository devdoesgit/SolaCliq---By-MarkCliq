//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

/// `customer`: the company installs for this person; they follow the install in the app.
enum Role {
  @JsonValue(r'org_admin')
  orgAdmin(r'org_admin'),
  @JsonValue(r'worker')
  worker(r'worker'),
  @JsonValue(r'agent')
  agent(r'agent'),
  @JsonValue(r'customer')
  customer(r'customer');

  const Role(this.value);

  final String value;

  @override
  String toString() => value;
}
