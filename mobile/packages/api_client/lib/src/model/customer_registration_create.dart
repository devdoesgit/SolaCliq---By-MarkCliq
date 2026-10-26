//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api_client/src/model/customer_registration_create_documents_inner.dart';
import 'package:api_client/src/model/connection_type.dart';
import 'package:api_client/src/model/roof_type.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'customer_registration_create.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class CustomerRegistrationCreate {
  /// Returns a new [CustomerRegistrationCreate] instance.
  CustomerRegistrationCreate({
    required this.name,

    required this.phone,

    required this.email,

    required this.address,

    required this.city,

    required this.pinCode,

    required this.state,

    required this.discom,

    required this.consumerNumber,

    required this.sanctionedLoadKw,

    required this.connectionType,

    required this.proposedKw,

    required this.roof,

    required this.subsidy,

    required this.documents,

    required this.consent,

    this.commission,

    this.commissionNote,
  });

  @JsonKey(name: r'name', required: true, includeIfNull: false)
  final String name;

  /// Indian mobile number, 10 digits, without +91.
  @JsonKey(name: r'phone', required: true, includeIfNull: false)
  final String phone;

  @JsonKey(name: r'email', required: true, includeIfNull: false)
  final String email;

  @JsonKey(name: r'address', required: true, includeIfNull: false)
  final String address;

  @JsonKey(name: r'city', required: true, includeIfNull: false)
  final String city;

  @JsonKey(name: r'pin_code', required: true, includeIfNull: false)
  final String pinCode;

  @JsonKey(name: r'state', required: true, includeIfNull: false)
  final String state;

  @JsonKey(name: r'discom', required: true, includeIfNull: false)
  final String discom;

  @JsonKey(name: r'consumer_number', required: true, includeIfNull: false)
  final String consumerNumber;

  // minimum: 0
  @JsonKey(name: r'sanctioned_load_kw', required: true, includeIfNull: false)
  final num sanctionedLoadKw;

  @JsonKey(name: r'connection_type', required: true, includeIfNull: false)
  final ConnectionType connectionType;

  // minimum: 0
  @JsonKey(name: r'proposed_kw', required: true, includeIfNull: false)
  final num proposedKw;

  @JsonKey(name: r'roof', required: true, includeIfNull: false)
  final RoofType roof;

  /// Apply for PM Surya Ghar.
  @JsonKey(name: r'subsidy', required: true, includeIfNull: false)
  final bool subsidy;

  @JsonKey(name: r'documents', required: true, includeIfNull: false)
  final List<CustomerRegistrationCreateDocumentsInner> documents;

  /// The customer agreed to share these with the company. Must be true.
  @JsonKey(name: r'consent', required: true, includeIfNull: false)
  final bool consent;

  /// Commission agents only (422 `registration.commission_not_allowed` for salaried ones). The admin approves or changes it.
  @JsonKey(name: r'commission', required: false, includeIfNull: false)
  final int? commission;

  /// How the agent worked it out.
  @JsonKey(name: r'commission_note', required: false, includeIfNull: false)
  final String? commissionNote;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is CustomerRegistrationCreate &&
            runtimeType == other.runtimeType &&
            equals(
              [
                name,
                phone,
                email,
                address,
                city,
                pinCode,
                state,
                discom,
                consumerNumber,
                sanctionedLoadKw,
                connectionType,
                proposedKw,
                roof,
                subsidy,
                documents,
                consent,
                commission,
                commissionNote,
              ],
              [
                other.name,
                other.phone,
                other.email,
                other.address,
                other.city,
                other.pinCode,
                other.state,
                other.discom,
                other.consumerNumber,
                other.sanctionedLoadKw,
                other.connectionType,
                other.proposedKw,
                other.roof,
                other.subsidy,
                other.documents,
                other.consent,
                other.commission,
                other.commissionNote,
              ],
            );
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^
      mapPropsToHashCode([
        name,
        phone,
        email,
        address,
        city,
        pinCode,
        state,
        discom,
        consumerNumber,
        sanctionedLoadKw,
        connectionType,
        proposedKw,
        roof,
        subsidy,
        documents,
        consent,
        commission,
        commissionNote,
      ]);

  factory CustomerRegistrationCreate.fromJson(Map<String, dynamic> json) =>
      _$CustomerRegistrationCreateFromJson(json);

  Map<String, dynamic> toJson() => _$CustomerRegistrationCreateToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
