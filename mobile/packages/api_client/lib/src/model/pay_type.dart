//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

/// Agents (shown as Sales) only, and always present for them. `commission` agents enter a commission on each customer they add; `salary` employees have no commission step. The app treats an agent without one as salaried.
enum PayType {
  @JsonValue(r'commission')
  commission(r'commission'),
  @JsonValue(r'salary')
  salary(r'salary');

  const PayType(this.value);

  final String value;

  @override
  String toString() => value;
}
