//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'lead_create.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class LeadCreate {
  /// Returns a new [LeadCreate] instance.
  LeadCreate({
    this.externalId,

    required this.name,

    required this.phone,

    this.email,

    this.city,

    this.pinCode,

    this.monthlyBill,

    this.roofType,

    this.message,

    this.source_,

    this.campaign,

    this.pageUrl,

    this.extra,

    required this.consent,
  });

  /// The landing page's own id for this form; a resend with it returns the first lead.
  @JsonKey(name: r'external_id', required: false, includeIfNull: false)
  final String? externalId;

  @JsonKey(name: r'name', required: true, includeIfNull: false)
  final String name;

  /// An Indian mobile number; +91, spaces and dashes are allowed.
  @JsonKey(name: r'phone', required: true, includeIfNull: false)
  final String phone;

  @JsonKey(name: r'email', required: false, includeIfNull: false)
  final String? email;

  @JsonKey(name: r'city', required: false, includeIfNull: false)
  final String? city;

  @JsonKey(name: r'pin_code', required: false, includeIfNull: false)
  final String? pinCode;

  /// As the form asked it, e.g. \"₹3,000 to ₹5,000\".
  @JsonKey(name: r'monthly_bill', required: false, includeIfNull: false)
  final String? monthlyBill;

  @JsonKey(name: r'roof_type', required: false, includeIfNull: false)
  final String? roofType;

  @JsonKey(name: r'message', required: false, includeIfNull: false)
  final String? message;

  /// Where the person came from, e.g. \"Meta ad\". Default \"Landing page\".
  @JsonKey(name: r'source', required: false, includeIfNull: false)
  final String? source_;

  @JsonKey(name: r'campaign', required: false, includeIfNull: false)
  final String? campaign;

  @JsonKey(name: r'page_url', required: false, includeIfNull: false)
  final String? pageUrl;

  /// Any other short answers from the form, by question (keys up to 60 characters).
  @JsonKey(name: r'extra', required: false, includeIfNull: false)
  final Map<String, String>? extra;

  /// The person agreed that the company may contact them. Must be true.
  @JsonKey(name: r'consent', required: true, includeIfNull: false)
  final bool consent;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is LeadCreate &&
            runtimeType == other.runtimeType &&
            equals(
              [
                externalId,
                name,
                phone,
                email,
                city,
                pinCode,
                monthlyBill,
                roofType,
                message,
                source_,
                campaign,
                pageUrl,
                extra,
                consent,
              ],
              [
                other.externalId,
                other.name,
                other.phone,
                other.email,
                other.city,
                other.pinCode,
                other.monthlyBill,
                other.roofType,
                other.message,
                other.source_,
                other.campaign,
                other.pageUrl,
                other.extra,
                other.consent,
              ],
            );
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^
      mapPropsToHashCode([
        externalId,
        name,
        phone,
        email,
        city,
        pinCode,
        monthlyBill,
        roofType,
        message,
        source_,
        campaign,
        pageUrl,
        extra,
        consent,
      ]);

  factory LeadCreate.fromJson(Map<String, dynamic> json) =>
      _$LeadCreateFromJson(json);

  Map<String, dynamic> toJson() => _$LeadCreateToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
