//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

enum AdminPaymentStatus {
  @JsonValue(r'due')
  due(r'due'),
  @JsonValue(r'claimed')
  claimed(r'claimed'),
  @JsonValue(r'paid')
  paid(r'paid'),
  @JsonValue(r'later')
  later(r'later');

  const AdminPaymentStatus(this.value);

  final String value;

  @override
  String toString() => value;
}
