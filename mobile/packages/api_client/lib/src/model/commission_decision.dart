//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'commission_decision.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class CommissionDecision {
  /// Returns a new [CommissionDecision] instance.
  CommissionDecision({this.amount, this.note});

  @JsonKey(name: r'amount', required: false, includeIfNull: false)
  final int? amount;

  @JsonKey(name: r'note', required: false, includeIfNull: false)
  final String? note;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is CommissionDecision &&
            runtimeType == other.runtimeType &&
            equals([amount, note], [other.amount, other.note]);
  }

  @override
  int get hashCode => runtimeType.hashCode ^ mapPropsToHashCode([amount, note]);

  factory CommissionDecision.fromJson(Map<String, dynamic> json) =>
      _$CommissionDecisionFromJson(json);

  Map<String, dynamic> toJson() => _$CommissionDecisionToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
