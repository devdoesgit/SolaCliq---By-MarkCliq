//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'quote_estimate.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class QuoteEstimate {
  /// Returns a new [QuoteEstimate] instance.
  QuoteEstimate({
    required this.kwMin,

    required this.kwMax,

    required this.priceMin,

    required this.priceMax,

    required this.subsidyMax,
  });

  @JsonKey(name: r'kw_min', required: true, includeIfNull: false)
  final num kwMin;

  @JsonKey(name: r'kw_max', required: true, includeIfNull: false)
  final num kwMax;

  /// Amount in paise (₹1 = 100). Never a float.
  @JsonKey(name: r'price_min', required: true, includeIfNull: false)
  final int priceMin;

  /// Amount in paise (₹1 = 100). Never a float.
  @JsonKey(name: r'price_max', required: true, includeIfNull: false)
  final int priceMax;

  /// Amount in paise (₹1 = 100). Never a float.
  @JsonKey(name: r'subsidy_max', required: true, includeIfNull: false)
  final int subsidyMax;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is QuoteEstimate &&
            runtimeType == other.runtimeType &&
            equals(
              [kwMin, kwMax, priceMin, priceMax, subsidyMax],
              [
                other.kwMin,
                other.kwMax,
                other.priceMin,
                other.priceMax,
                other.subsidyMax,
              ],
            );
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^
      mapPropsToHashCode([kwMin, kwMax, priceMin, priceMax, subsidyMax]);

  factory QuoteEstimate.fromJson(Map<String, dynamic> json) =>
      _$QuoteEstimateFromJson(json);

  Map<String, dynamic> toJson() => _$QuoteEstimateToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
