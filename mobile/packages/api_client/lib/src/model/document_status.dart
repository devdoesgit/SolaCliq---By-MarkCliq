//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

enum DocumentStatus {
  @JsonValue(r'verified')
  verified(r'verified'),
  @JsonValue(r'in_review')
  inReview(r'in_review'),
  @JsonValue(r'needs_fix')
  needsFix(r'needs_fix');

  const DocumentStatus(this.value);

  final String value;

  @override
  String toString() => value;
}
