//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

enum BusinessType {
  @JsonValue(r'proprietorship')
  proprietorship(r'proprietorship'),
  @JsonValue(r'partnership')
  partnership(r'partnership'),
  @JsonValue(r'llp')
  llp(r'llp'),
  @JsonValue(r'private_limited')
  privateLimited(r'private_limited'),
  @JsonValue(r'public_limited')
  publicLimited(r'public_limited'),
  @JsonValue(r'other')
  other(r'other');

  const BusinessType(this.value);

  final String value;

  @override
  String toString() => value;
}
