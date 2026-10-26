//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api_client/src/model/customer_detail_advance.dart';
import 'package:api_client/src/model/customer_detail_stage.dart';
import 'package:api_client/src/model/kyc_status.dart';
import 'package:api_client/src/model/customer_detail_documents.dart';
import 'package:api_client/src/model/commission.dart';
import 'package:api_client/src/model/customer_detail_returned.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'customer_detail.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class CustomerDetail {
  /// Returns a new [CustomerDetail] instance.
  CustomerDetail({
    required this.id,

    required this.name,

    required this.phone,

    required this.systemKw,

    required this.place,

    required this.kycStatus,

    required this.detail,

    required this.sentAt,

    this.stage,

    this.returned,

    this.documents,

    this.advance,

    this.commission,
  });

  /// UUIDv7.
  @JsonKey(name: r'id', required: true, includeIfNull: false)
  final String id;

  @JsonKey(name: r'name', required: true, includeIfNull: false)
  final String name;

  /// Indian mobile number, 10 digits, without +91.
  @JsonKey(name: r'phone', required: true, includeIfNull: false)
  final String phone;

  @JsonKey(name: r'system_kw', required: true, includeIfNull: false)
  final num systemKw;

  @JsonKey(name: r'place', required: true, includeIfNull: false)
  final String place;

  @JsonKey(name: r'kyc_status', required: true, includeIfNull: false)
  final KycStatus kycStatus;

  @JsonKey(name: r'detail', required: true, includeIfNull: false)
  final String detail;

  /// ISO 8601, UTC.
  @JsonKey(name: r'sent_at', required: true, includeIfNull: false)
  final DateTime sentAt;

  @JsonKey(name: r'stage', required: false, includeIfNull: false)
  final CustomerDetailStage? stage;

  @JsonKey(name: r'returned', required: false, includeIfNull: false)
  final CustomerDetailReturned? returned;

  @JsonKey(name: r'documents', required: false, includeIfNull: false)
  final CustomerDetailDocuments? documents;

  @JsonKey(name: r'advance', required: false, includeIfNull: false)
  final CustomerDetailAdvance? advance;

  @JsonKey(name: r'commission', required: false, includeIfNull: false)
  final Commission? commission;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is CustomerDetail &&
            runtimeType == other.runtimeType &&
            equals(
              [
                id,
                name,
                phone,
                systemKw,
                place,
                kycStatus,
                detail,
                sentAt,
                stage,
                returned,
                documents,
                advance,
                commission,
              ],
              [
                other.id,
                other.name,
                other.phone,
                other.systemKw,
                other.place,
                other.kycStatus,
                other.detail,
                other.sentAt,
                other.stage,
                other.returned,
                other.documents,
                other.advance,
                other.commission,
              ],
            );
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^
      mapPropsToHashCode([
        id,
        name,
        phone,
        systemKw,
        place,
        kycStatus,
        detail,
        sentAt,
        stage,
        returned,
        documents,
        advance,
        commission,
      ]);

  factory CustomerDetail.fromJson(Map<String, dynamic> json) =>
      _$CustomerDetailFromJson(json);

  Map<String, dynamic> toJson() => _$CustomerDetailToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
