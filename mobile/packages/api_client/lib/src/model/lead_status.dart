//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

enum LeadStatus {
  @JsonValue(r'new')
  new_(r'new'),
  @JsonValue(r'contacted')
  contacted(r'contacted'),
  @JsonValue(r'won')
  won(r'won'),
  @JsonValue(r'lost')
  lost(r'lost');

  const LeadStatus(this.value);

  final String value;

  @override
  String toString() => value;
}
