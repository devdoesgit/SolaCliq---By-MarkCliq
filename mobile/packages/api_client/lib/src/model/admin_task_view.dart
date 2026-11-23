//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

enum AdminTaskView {
  @JsonValue(r'open')
  open(r'open'),
  @JsonValue(r'assigned')
  assigned(r'assigned'),
  @JsonValue(r'returned')
  returned(r'returned'),
  @JsonValue(r'submitted')
  submitted(r'submitted'),
  @JsonValue(r'problem')
  problem(r'problem'),
  @JsonValue(r'done')
  done(r'done');

  const AdminTaskView(this.value);

  final String value;

  @override
  String toString() => value;
}
