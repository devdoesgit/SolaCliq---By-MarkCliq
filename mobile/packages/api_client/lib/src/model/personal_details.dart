//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api_client/src/model/payout_bank.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'personal_details.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PersonalDetails {
  /// Returns a new [PersonalDetails] instance.
  PersonalDetails({this.phone, this.address, this.emergencyContact, this.bank});

  /// Indian mobile number, 10 digits, without +91.
  @JsonKey(name: r'phone', required: false, includeIfNull: false)
  final String? phone;

  @JsonKey(name: r'address', required: false, includeIfNull: false)
  final String? address;

  @JsonKey(name: r'emergency_contact', required: false, includeIfNull: false)
  final String? emergencyContact;

  @JsonKey(name: r'bank', required: false, includeIfNull: false)
  final PayoutBank? bank;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is PersonalDetails &&
            runtimeType == other.runtimeType &&
            equals(
              [phone, address, emergencyContact, bank],
              [other.phone, other.address, other.emergencyContact, other.bank],
            );
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^
      mapPropsToHashCode([phone, address, emergencyContact, bank]);

  factory PersonalDetails.fromJson(Map<String, dynamic> json) =>
      _$PersonalDetailsFromJson(json);

  Map<String, dynamic> toJson() => _$PersonalDetailsToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
