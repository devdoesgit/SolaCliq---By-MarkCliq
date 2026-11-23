//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'price_set.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PriceSet {
  /// Returns a new [PriceSet] instance.
  PriceSet({required this.total, required this.subsidy});

  /// Amount in paise (₹1 = 100). Never a float.
  @JsonKey(name: r'total', required: true, includeIfNull: false)
  final int total;

  /// Amount in paise (₹1 = 100). Never a float.
  @JsonKey(name: r'subsidy', required: true, includeIfNull: false)
  final int subsidy;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is PriceSet &&
            runtimeType == other.runtimeType &&
            equals([total, subsidy], [other.total, other.subsidy]);
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^ mapPropsToHashCode([total, subsidy]);

  factory PriceSet.fromJson(Map<String, dynamic> json) =>
      _$PriceSetFromJson(json);

  Map<String, dynamic> toJson() => _$PriceSetToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
