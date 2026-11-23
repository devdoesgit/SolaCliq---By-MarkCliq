//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

/// `paid`: approved and paid out (with salary or cash). `rejected`: not accepted, with the admin's reason; final.
enum ExpenseStatus {
  @JsonValue(r'in_review')
  inReview(r'in_review'),
  @JsonValue(r'approved')
  approved(r'approved'),
  @JsonValue(r'needs_fix')
  needsFix(r'needs_fix'),
  @JsonValue(r'paid')
  paid(r'paid'),
  @JsonValue(r'rejected')
  rejected(r'rejected');

  const ExpenseStatus(this.value);

  final String value;

  @override
  String toString() => value;
}
