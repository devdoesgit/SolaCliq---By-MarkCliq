//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

enum ExpenseCategory {
  @JsonValue(r'fuel')
  fuel(r'fuel'),
  @JsonValue(r'material')
  material(r'material'),
  @JsonValue(r'labour')
  labour(r'labour'),
  @JsonValue(r'other')
  other(r'other');

  const ExpenseCategory(this.value);

  final String value;

  @override
  String toString() => value;
}
