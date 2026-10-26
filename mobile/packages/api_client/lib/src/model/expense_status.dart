//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

/// `paid`: approved and paid out (with salary or cash).
enum ExpenseStatus {
  @JsonValue(r'in_review')
  inReview(r'in_review'),
  @JsonValue(r'approved')
  approved(r'approved'),
  @JsonValue(r'needs_fix')
  needsFix(r'needs_fix'),
  @JsonValue(r'paid')
  paid(r'paid');

  const ExpenseStatus(this.value);

  final String value;

  @override
  String toString() => value;
}
