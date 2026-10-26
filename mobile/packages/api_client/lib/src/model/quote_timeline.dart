//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

enum QuoteTimeline {
  @JsonValue(r'this_month')
  thisMonth(r'this_month'),
  @JsonValue(r'in_1_to_3_months')
  in1To3Months(r'in_1_to_3_months'),
  @JsonValue(r'exploring')
  exploring(r'exploring');

  const QuoteTimeline(this.value);

  final String value;

  @override
  String toString() => value;
}
