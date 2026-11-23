//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'commission_totals.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class CommissionTotals {
  /// Returns a new [CommissionTotals] instance.
  CommissionTotals({
    required this.inReview,

    required this.waiting,

    required this.payable,

    required this.paidThisMonth,
  });

  /// Amount in paise (₹1 = 100). Never a float.
  @JsonKey(name: r'in_review', required: true, includeIfNull: false)
  final int inReview;

  /// Amount in paise (₹1 = 100). Never a float.
  @JsonKey(name: r'waiting', required: true, includeIfNull: false)
  final int waiting;

  /// Amount in paise (₹1 = 100). Never a float.
  @JsonKey(name: r'payable', required: true, includeIfNull: false)
  final int payable;

  /// Amount in paise (₹1 = 100). Never a float.
  @JsonKey(name: r'paid_this_month', required: true, includeIfNull: false)
  final int paidThisMonth;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is CommissionTotals &&
            runtimeType == other.runtimeType &&
            equals(
              [inReview, waiting, payable, paidThisMonth],
              [
                other.inReview,
                other.waiting,
                other.payable,
                other.paidThisMonth,
              ],
            );
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^
      mapPropsToHashCode([inReview, waiting, payable, paidThisMonth]);

  factory CommissionTotals.fromJson(Map<String, dynamic> json) =>
      _$CommissionTotalsFromJson(json);

  Map<String, dynamic> toJson() => _$CommissionTotalsToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
