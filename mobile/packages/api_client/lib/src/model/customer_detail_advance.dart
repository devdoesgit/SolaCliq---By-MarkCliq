//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'customer_detail_advance.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class CustomerDetailAdvance {
  /// Returns a new [CustomerDetailAdvance] instance.
  CustomerDetailAdvance({required this.status, this.paidOn});

  @JsonKey(name: r'status', required: true, includeIfNull: false)
  final CustomerDetailAdvanceStatusEnum status;

  @JsonKey(name: r'paid_on', required: false, includeIfNull: false)
  final String? paidOn;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is CustomerDetailAdvance &&
            runtimeType == other.runtimeType &&
            equals([status, paidOn], [other.status, other.paidOn]);
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^ mapPropsToHashCode([status, paidOn]);

  factory CustomerDetailAdvance.fromJson(Map<String, dynamic> json) =>
      _$CustomerDetailAdvanceFromJson(json);

  Map<String, dynamic> toJson() => _$CustomerDetailAdvanceToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum CustomerDetailAdvanceStatusEnum {
  @JsonValue(r'due')
  due(r'due'),
  @JsonValue(r'paid')
  paid(r'paid');

  const CustomerDetailAdvanceStatusEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
