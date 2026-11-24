//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api_client/src/model/platform_org_owner.dart';
import 'package:api_client/src/model/business_type.dart';
import 'package:api_client/src/model/org_status.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'platform_org.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PlatformOrg {
  /// Returns a new [PlatformOrg] instance.
  PlatformOrg({
    required this.id,

    required this.name,

    required this.legalName,

    required this.businessType,

    required this.gstin,

    required this.pan,

    required this.addressLine1,

    this.addressLine2,

    required this.city,

    required this.state,

    required this.pinCode,

    required this.phone,

    required this.status,

    this.owner,

    required this.createdAt,

    this.reviewedAt,

    this.reviewNote,
  });

  /// UUIDv7.
  @JsonKey(name: r'id', required: true, includeIfNull: false)
  final String id;

  /// Shown in the app (the trade name, or the legal name).
  @JsonKey(name: r'name', required: true, includeIfNull: false)
  final String name;

  @JsonKey(name: r'legal_name', required: true, includeIfNull: false)
  final String legalName;

  @JsonKey(name: r'business_type', required: true, includeIfNull: false)
  final BusinessType businessType;

  @JsonKey(name: r'gstin', required: true, includeIfNull: false)
  final String gstin;

  /// Characters 3–12 of the GSTIN.
  @JsonKey(name: r'pan', required: true, includeIfNull: false)
  final String pan;

  @JsonKey(name: r'address_line_1', required: true, includeIfNull: false)
  final String addressLine1;

  @JsonKey(name: r'address_line_2', required: false, includeIfNull: false)
  final String? addressLine2;

  @JsonKey(name: r'city', required: true, includeIfNull: false)
  final String city;

  /// From the GSTIN's first two digits.
  @JsonKey(name: r'state', required: true, includeIfNull: false)
  final String state;

  @JsonKey(name: r'pin_code', required: true, includeIfNull: false)
  final String pinCode;

  /// Indian mobile number, 10 digits, without +91.
  @JsonKey(name: r'phone', required: true, includeIfNull: false)
  final String phone;

  @JsonKey(name: r'status', required: true, includeIfNull: false)
  final OrgStatus status;

  @JsonKey(name: r'owner', required: false, includeIfNull: false)
  final PlatformOrgOwner? owner;

  /// ISO 8601, UTC.
  @JsonKey(name: r'created_at', required: true, includeIfNull: false)
  final DateTime createdAt;

  /// ISO 8601, UTC.
  @JsonKey(name: r'reviewed_at', required: false, includeIfNull: false)
  final DateTime? reviewedAt;

  @JsonKey(name: r'review_note', required: false, includeIfNull: false)
  final String? reviewNote;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is PlatformOrg &&
            runtimeType == other.runtimeType &&
            equals(
              [
                id,
                name,
                legalName,
                businessType,
                gstin,
                pan,
                addressLine1,
                addressLine2,
                city,
                state,
                pinCode,
                phone,
                status,
                owner,
                createdAt,
                reviewedAt,
                reviewNote,
              ],
              [
                other.id,
                other.name,
                other.legalName,
                other.businessType,
                other.gstin,
                other.pan,
                other.addressLine1,
                other.addressLine2,
                other.city,
                other.state,
                other.pinCode,
                other.phone,
                other.status,
                other.owner,
                other.createdAt,
                other.reviewedAt,
                other.reviewNote,
              ],
            );
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^
      mapPropsToHashCode([
        id,
        name,
        legalName,
        businessType,
        gstin,
        pan,
        addressLine1,
        addressLine2,
        city,
        state,
        pinCode,
        phone,
        status,
        owner,
        createdAt,
        reviewedAt,
        reviewNote,
      ]);

  factory PlatformOrg.fromJson(Map<String, dynamic> json) =>
      _$PlatformOrgFromJson(json);

  Map<String, dynamic> toJson() => _$PlatformOrgToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
