//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'customer_registration.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class CustomerRegistration {
  /// Returns a new [CustomerRegistration] instance.
  CustomerRegistration({
    required this.id,

    required this.reference,

    required this.status,
  });

  /// UUIDv7.
  @JsonKey(name: r'id', required: true, includeIfNull: false)
  final String id;

  @JsonKey(name: r'reference', required: true, includeIfNull: false)
  final String reference;

  @JsonKey(name: r'status', required: true, includeIfNull: false)
  final CustomerRegistrationStatusEnum status;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is CustomerRegistration &&
            runtimeType == other.runtimeType &&
            equals(
              [id, reference, status],
              [other.id, other.reference, other.status],
            );
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^ mapPropsToHashCode([id, reference, status]);

  factory CustomerRegistration.fromJson(Map<String, dynamic> json) =>
      _$CustomerRegistrationFromJson(json);

  Map<String, dynamic> toJson() => _$CustomerRegistrationToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum CustomerRegistrationStatusEnum {
  @JsonValue(r'submitted')
  submitted(r'submitted'),
  @JsonValue(r'verified')
  verified(r'verified'),
  @JsonValue(r'rejected')
  rejected(r'rejected');

  const CustomerRegistrationStatusEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
