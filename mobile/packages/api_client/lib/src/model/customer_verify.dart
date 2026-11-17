//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'customer_verify.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class CustomerVerify {
  /// Returns a new [CustomerVerify] instance.
  CustomerVerify({this.subsidy, required this.total});

  @JsonKey(name: r'subsidy', required: false, includeIfNull: false)
  final int? subsidy;

  @JsonKey(name: r'total', required: true, includeIfNull: false)
  final int total;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is CustomerVerify &&
            runtimeType == other.runtimeType &&
            equals([subsidy, total], [other.subsidy, other.total]);
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^ mapPropsToHashCode([subsidy, total]);

  factory CustomerVerify.fromJson(Map<String, dynamic> json) =>
      _$CustomerVerifyFromJson(json);

  Map<String, dynamic> toJson() => _$CustomerVerifyToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
