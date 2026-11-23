//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api_client/src/model/admin_payment_status.dart';
import 'package:api_client/src/model/connection_type.dart';
import 'package:api_client/src/model/admin_document.dart';
import 'package:api_client/src/model/admin_payment.dart';
import 'package:api_client/src/model/admin_stage.dart';
import 'package:api_client/src/model/kyc_status.dart';
import 'package:api_client/src/model/admin_commission.dart';
import 'package:api_client/src/model/admin_price.dart';
import 'package:api_client/src/model/roof_type.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'admin_customer.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AdminCustomer {
  /// Returns a new [AdminCustomer] instance.
  AdminCustomer({
    required this.id,

    required this.reference,

    required this.name,

    this.phone,

    required this.place,

    this.systemKw,

    required this.kycStatus,

    this.stage,

    this.agentName,

    this.advanceStatus,

    this.commissionAmount,

    required this.createdAt,

    this.email,

    required this.address,

    this.city,

    this.pinCode,

    this.state,

    this.discom,

    this.consumerNumber,

    this.sanctionedLoadKw,

    this.connectionType,

    this.roof,

    this.lat,

    this.lng,

    this.subsidyRequested,

    this.consentAt,

    required this.suggestedSubsidy,

    this.rejectedNote,

    this.handedOverOn,

    required this.documents,

    this.price,

    required this.payments,

    this.commission,
  });

  /// UUIDv7.
  @JsonKey(name: r'id', required: true, includeIfNull: false)
  final String id;

  @JsonKey(name: r'reference', required: true, includeIfNull: false)
  final String reference;

  @JsonKey(name: r'name', required: true, includeIfNull: false)
  final String name;

  @JsonKey(name: r'phone', required: false, includeIfNull: false)
  final String? phone;

  @JsonKey(name: r'place', required: true, includeIfNull: false)
  final String place;

  @JsonKey(name: r'system_kw', required: false, includeIfNull: false)
  final num? systemKw;

  @JsonKey(name: r'kyc_status', required: true, includeIfNull: false)
  final KycStatus kycStatus;

  @JsonKey(name: r'stage', required: false, includeIfNull: false)
  final AdminStage? stage;

  @JsonKey(name: r'agent_name', required: false, includeIfNull: false)
  final String? agentName;

  @JsonKey(name: r'advance_status', required: false, includeIfNull: false)
  final AdminPaymentStatus? advanceStatus;

  /// Amount in paise (₹1 = 100). Never a float.
  @JsonKey(name: r'commission_amount', required: false, includeIfNull: false)
  final int? commissionAmount;

  /// ISO 8601, UTC.
  @JsonKey(name: r'created_at', required: true, includeIfNull: false)
  final DateTime createdAt;

  @JsonKey(name: r'email', required: false, includeIfNull: false)
  final String? email;

  @JsonKey(name: r'address', required: true, includeIfNull: false)
  final String address;

  @JsonKey(name: r'city', required: false, includeIfNull: false)
  final String? city;

  @JsonKey(name: r'pin_code', required: false, includeIfNull: false)
  final String? pinCode;

  @JsonKey(name: r'state', required: false, includeIfNull: false)
  final String? state;

  @JsonKey(name: r'discom', required: false, includeIfNull: false)
  final String? discom;

  @JsonKey(name: r'consumer_number', required: false, includeIfNull: false)
  final String? consumerNumber;

  @JsonKey(name: r'sanctioned_load_kw', required: false, includeIfNull: false)
  final num? sanctionedLoadKw;

  @JsonKey(name: r'connection_type', required: false, includeIfNull: false)
  final ConnectionType? connectionType;

  @JsonKey(name: r'roof', required: false, includeIfNull: false)
  final RoofType? roof;

  @JsonKey(name: r'lat', required: false, includeIfNull: false)
  final num? lat;

  @JsonKey(name: r'lng', required: false, includeIfNull: false)
  final num? lng;

  @JsonKey(name: r'subsidy_requested', required: false, includeIfNull: false)
  final bool? subsidyRequested;

  /// ISO 8601, UTC.
  @JsonKey(name: r'consent_at', required: false, includeIfNull: false)
  final DateTime? consentAt;

  /// Amount in paise (₹1 = 100). Never a float.
  @JsonKey(name: r'suggested_subsidy', required: true, includeIfNull: false)
  final int suggestedSubsidy;

  @JsonKey(name: r'rejected_note', required: false, includeIfNull: false)
  final String? rejectedNote;

  @JsonKey(name: r'handed_over_on', required: false, includeIfNull: false)
  final String? handedOverOn;

  @JsonKey(name: r'documents', required: true, includeIfNull: false)
  final List<AdminDocument> documents;

  @JsonKey(name: r'price', required: false, includeIfNull: false)
  final AdminPrice? price;

  @JsonKey(name: r'payments', required: true, includeIfNull: false)
  final List<AdminPayment> payments;

  @JsonKey(name: r'commission', required: false, includeIfNull: false)
  final AdminCommission? commission;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is AdminCustomer &&
            runtimeType == other.runtimeType &&
            equals(
              [
                id,
                reference,
                name,
                phone,
                place,
                systemKw,
                kycStatus,
                stage,
                agentName,
                advanceStatus,
                commissionAmount,
                createdAt,
                email,
                address,
                city,
                pinCode,
                state,
                discom,
                consumerNumber,
                sanctionedLoadKw,
                connectionType,
                roof,
                lat,
                lng,
                subsidyRequested,
                consentAt,
                suggestedSubsidy,
                rejectedNote,
                handedOverOn,
                documents,
                price,
                payments,
                commission,
              ],
              [
                other.id,
                other.reference,
                other.name,
                other.phone,
                other.place,
                other.systemKw,
                other.kycStatus,
                other.stage,
                other.agentName,
                other.advanceStatus,
                other.commissionAmount,
                other.createdAt,
                other.email,
                other.address,
                other.city,
                other.pinCode,
                other.state,
                other.discom,
                other.consumerNumber,
                other.sanctionedLoadKw,
                other.connectionType,
                other.roof,
                other.lat,
                other.lng,
                other.subsidyRequested,
                other.consentAt,
                other.suggestedSubsidy,
                other.rejectedNote,
                other.handedOverOn,
                other.documents,
                other.price,
                other.payments,
                other.commission,
              ],
            );
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^
      mapPropsToHashCode([
        id,
        reference,
        name,
        phone,
        place,
        systemKw,
        kycStatus,
        stage,
        agentName,
        advanceStatus,
        commissionAmount,
        createdAt,
        email,
        address,
        city,
        pinCode,
        state,
        discom,
        consumerNumber,
        sanctionedLoadKw,
        connectionType,
        roof,
        lat,
        lng,
        subsidyRequested,
        consentAt,
        suggestedSubsidy,
        rejectedNote,
        handedOverOn,
        documents,
        price,
        payments,
        commission,
      ]);

  factory AdminCustomer.fromJson(Map<String, dynamic> json) =>
      _$AdminCustomerFromJson(json);

  Map<String, dynamic> toJson() => _$AdminCustomerToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
