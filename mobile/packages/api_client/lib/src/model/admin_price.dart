//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'admin_price.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AdminPrice {
  /// Returns a new [AdminPrice] instance.
  AdminPrice({
    required this.total,

    required this.subsidy,

    required this.editable,
  });

  /// Amount in paise (₹1 = 100). Never a float.
  @JsonKey(name: r'total', required: true, includeIfNull: false)
  final int total;

  /// Amount in paise (₹1 = 100). Never a float.
  @JsonKey(name: r'subsidy', required: true, includeIfNull: false)
  final int subsidy;

  /// No payment is paid yet.
  @JsonKey(name: r'editable', required: true, includeIfNull: false)
  final bool editable;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is AdminPrice &&
            runtimeType == other.runtimeType &&
            equals(
              [total, subsidy, editable],
              [other.total, other.subsidy, other.editable],
            );
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^ mapPropsToHashCode([total, subsidy, editable]);

  factory AdminPrice.fromJson(Map<String, dynamic> json) =>
      _$AdminPriceFromJson(json);

  Map<String, dynamic> toJson() => _$AdminPriceToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
