//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

/// `pending` until MarkCliq reviews the registration; then `active` or `rejected`. `suspended` for non-payment or abuse. Only `active` companies give their members any data.
enum OrgStatus {
  @JsonValue(r'pending')
  pending(r'pending'),
  @JsonValue(r'active')
  active(r'active'),
  @JsonValue(r'suspended')
  suspended(r'suspended'),
  @JsonValue(r'rejected')
  rejected(r'rejected');

  const OrgStatus(this.value);

  final String value;

  @override
  String toString() => value;
}
