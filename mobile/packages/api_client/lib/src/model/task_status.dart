//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

/// `assigned`: to do (may have an open `problem`). `submitted`: with the admin. `returned`: the admin asked for changes. `approved` and `cancelled` are final.
enum TaskStatus {
  @JsonValue(r'assigned')
  assigned(r'assigned'),
  @JsonValue(r'submitted')
  submitted(r'submitted'),
  @JsonValue(r'returned')
  returned(r'returned'),
  @JsonValue(r'approved')
  approved(r'approved'),
  @JsonValue(r'cancelled')
  cancelled(r'cancelled');

  const TaskStatus(this.value);

  final String value;

  @override
  String toString() => value;
}
