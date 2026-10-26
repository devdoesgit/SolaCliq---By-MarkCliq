//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'install_payment.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class InstallPayment {
  /// Returns a new [InstallPayment] instance.
  InstallPayment({
    required this.id,

    required this.label,

    this.detail,

    required this.amount,

    this.dueOn,

    required this.status,
  });

  /// UUIDv7.
  @JsonKey(name: r'id', required: true, includeIfNull: false)
  final String id;

  @JsonKey(name: r'label', required: true, includeIfNull: false)
  final String label;

  @JsonKey(name: r'detail', required: false, includeIfNull: false)
  final String? detail;

  /// Amount in paise (₹1 = 100). Never a float.
  @JsonKey(name: r'amount', required: true, includeIfNull: false)
  final int amount;

  @JsonKey(name: r'due_on', required: false, includeIfNull: false)
  final String? dueOn;

  /// `claimed`: the customer says they paid; the company confirms.
  @JsonKey(name: r'status', required: true, includeIfNull: false)
  final InstallPaymentStatusEnum status;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is InstallPayment &&
            runtimeType == other.runtimeType &&
            equals(
              [id, label, detail, amount, dueOn, status],
              [
                other.id,
                other.label,
                other.detail,
                other.amount,
                other.dueOn,
                other.status,
              ],
            );
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^
      mapPropsToHashCode([id, label, detail, amount, dueOn, status]);

  factory InstallPayment.fromJson(Map<String, dynamic> json) =>
      _$InstallPaymentFromJson(json);

  Map<String, dynamic> toJson() => _$InstallPaymentToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

/// `claimed`: the customer says they paid; the company confirms.
enum InstallPaymentStatusEnum {
  @JsonValue(r'due')
  due(r'due'),
  @JsonValue(r'claimed')
  claimed(r'claimed'),
  @JsonValue(r'paid')
  paid(r'paid'),
  @JsonValue(r'later')
  later(r'later');

  const InstallPaymentStatusEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
