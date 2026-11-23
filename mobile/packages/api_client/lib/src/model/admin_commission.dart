//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api_client/src/model/commission_status.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'admin_commission.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AdminCommission {
  /// Returns a new [AdminCommission] instance.
  AdminCommission({
    required this.customerId,

    required this.customerName,

    required this.customerReference,

    this.agentName,

    required this.amount,

    this.proposedAmount,

    this.note,

    this.adminNote,

    required this.status,

    required this.advancePaid,

    this.payableSince,

    this.paidOn,

    this.payoutLast4,
  });

  /// UUIDv7.
  @JsonKey(name: r'customer_id', required: true, includeIfNull: false)
  final String customerId;

  @JsonKey(name: r'customer_name', required: true, includeIfNull: false)
  final String customerName;

  @JsonKey(name: r'customer_reference', required: true, includeIfNull: false)
  final String customerReference;

  @JsonKey(name: r'agent_name', required: false, includeIfNull: false)
  final String? agentName;

  /// Amount in paise (₹1 = 100). Never a float.
  @JsonKey(name: r'amount', required: true, includeIfNull: false)
  final int amount;

  /// Amount in paise (₹1 = 100). Never a float.
  @JsonKey(name: r'proposed_amount', required: false, includeIfNull: false)
  final int? proposedAmount;

  @JsonKey(name: r'note', required: false, includeIfNull: false)
  final String? note;

  @JsonKey(name: r'admin_note', required: false, includeIfNull: false)
  final String? adminNote;

  @JsonKey(name: r'status', required: true, includeIfNull: false)
  final CommissionStatus status;

  @JsonKey(name: r'advance_paid', required: true, includeIfNull: false)
  final bool advancePaid;

  @JsonKey(name: r'payable_since', required: false, includeIfNull: false)
  final String? payableSince;

  @JsonKey(name: r'paid_on', required: false, includeIfNull: false)
  final String? paidOn;

  /// The last 4 digits of the payout account, never more.
  @JsonKey(name: r'payout_last4', required: false, includeIfNull: false)
  final String? payoutLast4;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is AdminCommission &&
            runtimeType == other.runtimeType &&
            equals(
              [
                customerId,
                customerName,
                customerReference,
                agentName,
                amount,
                proposedAmount,
                note,
                adminNote,
                status,
                advancePaid,
                payableSince,
                paidOn,
                payoutLast4,
              ],
              [
                other.customerId,
                other.customerName,
                other.customerReference,
                other.agentName,
                other.amount,
                other.proposedAmount,
                other.note,
                other.adminNote,
                other.status,
                other.advancePaid,
                other.payableSince,
                other.paidOn,
                other.payoutLast4,
              ],
            );
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^
      mapPropsToHashCode([
        customerId,
        customerName,
        customerReference,
        agentName,
        amount,
        proposedAmount,
        note,
        adminNote,
        status,
        advancePaid,
        payableSince,
        paidOn,
        payoutLast4,
      ]);

  factory AdminCommission.fromJson(Map<String, dynamic> json) =>
      _$AdminCommissionFromJson(json);

  Map<String, dynamic> toJson() => _$AdminCommissionToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
