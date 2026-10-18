//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

/// `invited` until the person has set a password.
enum MemberStatus {
  @JsonValue(r'invited')
  invited(r'invited'),
  @JsonValue(r'active')
  active(r'active');

  const MemberStatus(this.value);

  final String value;

  @override
  String toString() => value;
}
