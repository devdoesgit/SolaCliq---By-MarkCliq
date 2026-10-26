//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

enum KycKind {
  @JsonValue(r'aadhaar')
  aadhaar(r'aadhaar'),
  @JsonValue(r'pan')
  pan(r'pan'),
  @JsonValue(r'electricity_bill')
  electricityBill(r'electricity_bill'),
  @JsonValue(r'bank_proof')
  bankProof(r'bank_proof'),
  @JsonValue(r'roof_photo')
  roofPhoto(r'roof_photo');

  const KycKind(this.value);

  final String value;

  @override
  String toString() => value;
}
