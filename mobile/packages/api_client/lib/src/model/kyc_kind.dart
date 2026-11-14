//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

/// `land_document`: proof the customer owns the property. `signature`: a photo of the customer's signature. `name_change`: when the electricity bill is in another person's name, the paper that explains it; the admin judges it. Any kind can be a JPEG, PNG or PDF upload.
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
  roofPhoto(r'roof_photo'),
  @JsonValue(r'land_document')
  landDocument(r'land_document'),
  @JsonValue(r'signature')
  signature(r'signature'),
  @JsonValue(r'name_change')
  nameChange(r'name_change');

  const KycKind(this.value);

  final String value;

  @override
  String toString() => value;
}
