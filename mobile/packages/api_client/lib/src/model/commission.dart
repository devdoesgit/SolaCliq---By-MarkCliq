//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api_client/src/model/task_note.dart';
import 'package:api_client/src/model/commission_status.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'commission.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class Commission {
  /// Returns a new [Commission] instance.
  Commission({
    required this.amount,

    this.proposedAmount,

    required this.status,

    this.adminNote,

    this.payableSince,

    this.paidOn,
  });

  /// Amount in paise (₹1 = 100). Never a float.
  @JsonKey(name: r'amount', required: true, includeIfNull: false)
  final int amount;

  /// What the agent asked, when the admin changed it.
  @JsonKey(name: r'proposed_amount', required: false, includeIfNull: false)
  final int? proposedAmount;

  @JsonKey(name: r'status', required: true, includeIfNull: false)
  final CommissionStatus status;

  @JsonKey(name: r'admin_note', required: false, includeIfNull: false)
  final TaskNote? adminNote;

  @JsonKey(name: r'payable_since', required: false, includeIfNull: false)
  final String? payableSince;

  @JsonKey(name: r'paid_on', required: false, includeIfNull: false)
  final String? paidOn;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is Commission &&
            runtimeType == other.runtimeType &&
            equals(
              [amount, proposedAmount, status, adminNote, payableSince, paidOn],
              [
                other.amount,
                other.proposedAmount,
                other.status,
                other.adminNote,
                other.payableSince,
                other.paidOn,
              ],
            );
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^
      mapPropsToHashCode([
        amount,
        proposedAmount,
        status,
        adminNote,
        payableSince,
        paidOn,
      ]);

  factory Commission.fromJson(Map<String, dynamic> json) =>
      _$CommissionFromJson(json);

  Map<String, dynamic> toJson() => _$CommissionToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
