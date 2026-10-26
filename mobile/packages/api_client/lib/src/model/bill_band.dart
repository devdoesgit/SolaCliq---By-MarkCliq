//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

/// Monthly electricity bill, in rupees.
enum BillBand {
  @JsonValue(r'under_1500')
  under1500(r'under_1500'),
  @JsonValue(r'from_1500_to_3000')
  from1500To3000(r'from_1500_to_3000'),
  @JsonValue(r'from_3000_to_6000')
  from3000To6000(r'from_3000_to_6000'),
  @JsonValue(r'over_6000')
  over6000(r'over_6000');

  const BillBand(this.value);

  final String value;

  @override
  String toString() => value;
}
