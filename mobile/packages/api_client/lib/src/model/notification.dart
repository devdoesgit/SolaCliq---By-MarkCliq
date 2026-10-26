//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'notification.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class Notification {
  /// Returns a new [Notification] instance.
  Notification({
    required this.id,

    required this.kind,

    required this.title,

    required this.body,

    required this.at,

    required this.read,

    this.taskId,

    this.expenseId,

    this.customerId,
  });

  /// UUIDv7.
  @JsonKey(name: r'id', required: true, includeIfNull: false)
  final String id;

  @JsonKey(name: r'kind', required: true, includeIfNull: false)
  final NotificationKindEnum kind;

  @JsonKey(name: r'title', required: true, includeIfNull: false)
  final String title;

  @JsonKey(name: r'body', required: true, includeIfNull: false)
  final String body;

  /// ISO 8601, UTC.
  @JsonKey(name: r'at', required: true, includeIfNull: false)
  final DateTime at;

  @JsonKey(name: r'read', required: true, includeIfNull: false)
  final bool read;

  /// UUIDv7.
  @JsonKey(name: r'task_id', required: false, includeIfNull: false)
  final String? taskId;

  /// UUIDv7.
  @JsonKey(name: r'expense_id', required: false, includeIfNull: false)
  final String? expenseId;

  /// One of the caller's customers (Sales).
  @JsonKey(name: r'customer_id', required: false, includeIfNull: false)
  final String? customerId;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is Notification &&
            runtimeType == other.runtimeType &&
            equals(
              [id, kind, title, body, at, read, taskId, expenseId, customerId],
              [
                other.id,
                other.kind,
                other.title,
                other.body,
                other.at,
                other.read,
                other.taskId,
                other.expenseId,
                other.customerId,
              ],
            );
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^
      mapPropsToHashCode([
        id,
        kind,
        title,
        body,
        at,
        read,
        taskId,
        expenseId,
        customerId,
      ]);

  factory Notification.fromJson(Map<String, dynamic> json) =>
      _$NotificationFromJson(json);

  Map<String, dynamic> toJson() => _$NotificationToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum NotificationKindEnum {
  @JsonValue(r'task_assigned')
  taskAssigned(r'task_assigned'),
  @JsonValue(r'task_approved')
  taskApproved(r'task_approved'),
  @JsonValue(r'task_returned')
  taskReturned(r'task_returned'),
  @JsonValue(r'task_cancelled')
  taskCancelled(r'task_cancelled'),
  @JsonValue(r'task_rescheduled')
  taskRescheduled(r'task_rescheduled'),
  @JsonValue(r'expense_approved')
  expenseApproved(r'expense_approved'),
  @JsonValue(r'expense_returned')
  expenseReturned(r'expense_returned'),
  @JsonValue(r'expense_paid')
  expensePaid(r'expense_paid'),
  @JsonValue(r'kyc_returned')
  kycReturned(r'kyc_returned'),
  @JsonValue(r'kyc_submitted')
  kycSubmitted(r'kyc_submitted'),
  @JsonValue(r'kyc_approved')
  kycApproved(r'kyc_approved'),
  @JsonValue(r'install_started')
  installStarted(r'install_started'),
  @JsonValue(r'commission_changed')
  commissionChanged(r'commission_changed'),
  @JsonValue(r'commission_payable')
  commissionPayable(r'commission_payable'),
  @JsonValue(r'commission_paid')
  commissionPaid(r'commission_paid'),
  @JsonValue(r'visit_booked')
  visitBooked(r'visit_booked'),
  @JsonValue(r'payment_due')
  paymentDue(r'payment_due'),
  @JsonValue(r'documents_verified')
  documentsVerified(r'documents_verified'),
  @JsonValue(r'quote_shared')
  quoteShared(r'quote_shared'),
  @JsonValue(r'invite_received')
  inviteReceived(r'invite_received'),
  @JsonValue(r'guide')
  guide(r'guide');

  const NotificationKindEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
