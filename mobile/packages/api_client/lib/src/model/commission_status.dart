//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

/// `approved` waits for the customer's advance; `payable` once it is paid; `paid` when the admin pays it out.
enum CommissionStatus {
  @JsonValue(r'in_review')
  inReview(r'in_review'),
  @JsonValue(r'approved')
  approved(r'approved'),
  @JsonValue(r'payable')
  payable(r'payable'),
  @JsonValue(r'paid')
  paid(r'paid');

  const CommissionStatus(this.value);

  final String value;

  @override
  String toString() => value;
}
