//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api_client/src/model/business_type.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'org_registration_create.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class OrgRegistrationCreate {
  /// Returns a new [OrgRegistrationCreate] instance.
  OrgRegistrationCreate({
    required this.termsVersion,

    required this.legalName,

    this.tradeName,

    required this.businessType,

    required this.gstin,

    required this.addressLine1,

    this.addressLine2,

    required this.city,

    required this.pinCode,

    required this.ownerName,

    required this.email,

    required this.phone,
  });

  /// The owner agreed to the Terms of Use, the Privacy Policy and the Company Terms (two ticks in the form, both required before the app sends). Records two agreements: the owner's, and the company's with its id. Same rules as `TermsVersion`.
  // minimum: 1
  @JsonKey(name: r'terms_version', required: true, includeIfNull: false)
  final int termsVersion;

  /// As on the GST certificate.
  @JsonKey(name: r'legal_name', required: true, includeIfNull: false)
  final String legalName;

  /// The name shown in the app. Left out → the legal name.
  @JsonKey(name: r'trade_name', required: false, includeIfNull: false)
  final String? tradeName;

  @JsonKey(name: r'business_type', required: true, includeIfNull: false)
  final BusinessType businessType;

  /// 15 characters; case and spaces don't matter.
  @JsonKey(name: r'gstin', required: true, includeIfNull: false)
  final String gstin;

  @JsonKey(name: r'address_line_1', required: true, includeIfNull: false)
  final String addressLine1;

  @JsonKey(name: r'address_line_2', required: false, includeIfNull: false)
  final String? addressLine2;

  @JsonKey(name: r'city', required: true, includeIfNull: false)
  final String city;

  @JsonKey(name: r'pin_code', required: true, includeIfNull: false)
  final String pinCode;

  @JsonKey(name: r'owner_name', required: true, includeIfNull: false)
  final String ownerName;

  @JsonKey(name: r'email', required: true, includeIfNull: false)
  final String email;

  /// Indian mobile number, 10 digits, without +91.
  @JsonKey(name: r'phone', required: true, includeIfNull: false)
  final String phone;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is OrgRegistrationCreate &&
            runtimeType == other.runtimeType &&
            equals(
              [
                termsVersion,
                legalName,
                tradeName,
                businessType,
                gstin,
                addressLine1,
                addressLine2,
                city,
                pinCode,
                ownerName,
                email,
                phone,
              ],
              [
                other.termsVersion,
                other.legalName,
                other.tradeName,
                other.businessType,
                other.gstin,
                other.addressLine1,
                other.addressLine2,
                other.city,
                other.pinCode,
                other.ownerName,
                other.email,
                other.phone,
              ],
            );
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^
      mapPropsToHashCode([
        termsVersion,
        legalName,
        tradeName,
        businessType,
        gstin,
        addressLine1,
        addressLine2,
        city,
        pinCode,
        ownerName,
        email,
        phone,
      ]);

  factory OrgRegistrationCreate.fromJson(Map<String, dynamic> json) =>
      _$OrgRegistrationCreateFromJson(json);

  Map<String, dynamic> toJson() => _$OrgRegistrationCreateToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
