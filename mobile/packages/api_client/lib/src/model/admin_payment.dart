//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api_client/src/model/admin_payment_status.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'admin_payment.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AdminPayment {
  /// Returns a new [AdminPayment] instance.
  AdminPayment({
    required this.id,

    required this.customerId,

    required this.customerName,

    required this.customerReference,

    required this.label,

    required this.amount,

    required this.status,

    this.dueOn,

    this.claimedAt,

    this.claimedMethod,

    this.paidOn,
  });

  /// UUIDv7.
  @JsonKey(name: r'id', required: true, includeIfNull: false)
  final String id;

  /// UUIDv7.
  @JsonKey(name: r'customer_id', required: true, includeIfNull: false)
  final String customerId;

  @JsonKey(name: r'customer_name', required: true, includeIfNull: false)
  final String customerName;

  @JsonKey(name: r'customer_reference', required: true, includeIfNull: false)
  final String customerReference;

  @JsonKey(name: r'label', required: true, includeIfNull: false)
  final String label;

  /// Amount in paise (₹1 = 100). Never a float.
  @JsonKey(name: r'amount', required: true, includeIfNull: false)
  final int amount;

  @JsonKey(name: r'status', required: true, includeIfNull: false)
  final AdminPaymentStatus status;

  @JsonKey(name: r'due_on', required: false, includeIfNull: false)
  final String? dueOn;

  /// ISO 8601, UTC.
  @JsonKey(name: r'claimed_at', required: false, includeIfNull: false)
  final DateTime? claimedAt;

  @JsonKey(name: r'claimed_method', required: false, includeIfNull: false)
  final AdminPaymentClaimedMethodEnum? claimedMethod;

  @JsonKey(name: r'paid_on', required: false, includeIfNull: false)
  final String? paidOn;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is AdminPayment &&
            runtimeType == other.runtimeType &&
            equals(
              [
                id,
                customerId,
                customerName,
                customerReference,
                label,
                amount,
                status,
                dueOn,
                claimedAt,
                claimedMethod,
                paidOn,
              ],
              [
                other.id,
                other.customerId,
                other.customerName,
                other.customerReference,
                other.label,
                other.amount,
                other.status,
                other.dueOn,
                other.claimedAt,
                other.claimedMethod,
                other.paidOn,
              ],
            );
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^
      mapPropsToHashCode([
        id,
        customerId,
        customerName,
        customerReference,
        label,
        amount,
        status,
        dueOn,
        claimedAt,
        claimedMethod,
        paidOn,
      ]);

  factory AdminPayment.fromJson(Map<String, dynamic> json) =>
      _$AdminPaymentFromJson(json);

  Map<String, dynamic> toJson() => _$AdminPaymentToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum AdminPaymentClaimedMethodEnum {
  @JsonValue(r'upi')
  upi(r'upi'),
  @JsonValue(r'bank_transfer')
  bankTransfer(r'bank_transfer');

  const AdminPaymentClaimedMethodEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
