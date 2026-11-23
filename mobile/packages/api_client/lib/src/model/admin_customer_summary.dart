//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api_client/src/model/admin_payment_status.dart';
import 'package:api_client/src/model/admin_stage.dart';
import 'package:api_client/src/model/kyc_status.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'admin_customer_summary.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AdminCustomerSummary {
  /// Returns a new [AdminCustomerSummary] instance.
  AdminCustomerSummary({
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

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is AdminCustomerSummary &&
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
      ]);

  factory AdminCustomerSummary.fromJson(Map<String, dynamic> json) =>
      _$AdminCustomerSummaryFromJson(json);

  Map<String, dynamic> toJson() => _$AdminCustomerSummaryToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
