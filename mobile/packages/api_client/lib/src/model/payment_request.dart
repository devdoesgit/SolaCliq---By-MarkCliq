//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'payment_request.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PaymentRequest {
  /// Returns a new [PaymentRequest] instance.
  PaymentRequest({required this.dueOn});

  @JsonKey(name: r'due_on', required: true, includeIfNull: false)
  final String dueOn;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is PaymentRequest &&
            runtimeType == other.runtimeType &&
            equals([dueOn], [other.dueOn]);
  }

  @override
  int get hashCode => runtimeType.hashCode ^ mapPropsToHashCode([dueOn]);

  factory PaymentRequest.fromJson(Map<String, dynamic> json) =>
      _$PaymentRequestFromJson(json);

  Map<String, dynamic> toJson() => _$PaymentRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
