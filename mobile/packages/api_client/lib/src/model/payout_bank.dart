//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'payout_bank.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PayoutBank {
  /// Returns a new [PayoutBank] instance.
  PayoutBank({
    this.holder,

    this.accountNumber,

    this.accountLast4,

    this.ifsc,

    this.bankName,
  });

  @JsonKey(name: r'holder', required: false, includeIfNull: false)
  final String? holder;

  /// Sent to change it; never returned.
  @JsonKey(name: r'account_number', required: false, includeIfNull: false)
  final String? accountNumber;

  @JsonKey(name: r'account_last4', required: false, includeIfNull: false)
  final String? accountLast4;

  @JsonKey(name: r'ifsc', required: false, includeIfNull: false)
  final String? ifsc;

  @JsonKey(name: r'bank_name', required: false, includeIfNull: false)
  final String? bankName;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is PayoutBank &&
            runtimeType == other.runtimeType &&
            equals(
              [holder, accountNumber, accountLast4, ifsc, bankName],
              [
                other.holder,
                other.accountNumber,
                other.accountLast4,
                other.ifsc,
                other.bankName,
              ],
            );
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^
      mapPropsToHashCode([holder, accountNumber, accountLast4, ifsc, bankName]);

  factory PayoutBank.fromJson(Map<String, dynamic> json) =>
      _$PayoutBankFromJson(json);

  Map<String, dynamic> toJson() => _$PayoutBankToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
