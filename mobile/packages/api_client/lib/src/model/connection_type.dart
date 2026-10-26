//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

enum ConnectionType {
  @JsonValue(r'residential')
  residential(r'residential'),
  @JsonValue(r'commercial')
  commercial(r'commercial'),
  @JsonValue(r'industrial')
  industrial(r'industrial');

  const ConnectionType(this.value);

  final String value;

  @override
  String toString() => value;
}
