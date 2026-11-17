//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

/// `rejected`: the company decided not to take the customer up; they stay in the agent's list.
enum KycStatus {
  @JsonValue(r'in_review')
  inReview(r'in_review'),
  @JsonValue(r'needs_fix')
  needsFix(r'needs_fix'),
  @JsonValue(r'approved')
  approved(r'approved'),
  @JsonValue(r'rejected')
  rejected(r'rejected');

  const KycStatus(this.value);

  final String value;

  @override
  String toString() => value;
}
