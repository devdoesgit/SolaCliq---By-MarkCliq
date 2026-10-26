//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'claim_install_payment_request.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ClaimInstallPaymentRequest {
  /// Returns a new [ClaimInstallPaymentRequest] instance.
  ClaimInstallPaymentRequest({required this.method});

  @JsonKey(name: r'method', required: true, includeIfNull: false)
  final ClaimInstallPaymentRequestMethodEnum method;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is ClaimInstallPaymentRequest &&
            runtimeType == other.runtimeType &&
            equals([method], [other.method]);
  }

  @override
  int get hashCode => runtimeType.hashCode ^ mapPropsToHashCode([method]);

  factory ClaimInstallPaymentRequest.fromJson(Map<String, dynamic> json) =>
      _$ClaimInstallPaymentRequestFromJson(json);

  Map<String, dynamic> toJson() => _$ClaimInstallPaymentRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum ClaimInstallPaymentRequestMethodEnum {
  @JsonValue(r'upi')
  upi(r'upi'),
  @JsonValue(r'bank_transfer')
  bankTransfer(r'bank_transfer');

  const ClaimInstallPaymentRequestMethodEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
