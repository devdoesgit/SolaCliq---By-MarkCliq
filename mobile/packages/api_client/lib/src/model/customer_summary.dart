//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api_client/src/model/kyc_status.dart';
import 'package:api_client/src/model/commission.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'customer_summary.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class CustomerSummary {
  /// Returns a new [CustomerSummary] instance.
  CustomerSummary({
    required this.id,

    required this.name,

    required this.systemKw,

    required this.place,

    required this.kycStatus,

    required this.detail,

    required this.sentAt,

    this.commission,
  });

  /// UUIDv7.
  @JsonKey(name: r'id', required: true, includeIfNull: false)
  final String id;

  @JsonKey(name: r'name', required: true, includeIfNull: false)
  final String name;

  @JsonKey(name: r'system_kw', required: true, includeIfNull: false)
  final num systemKw;

  @JsonKey(name: r'place', required: true, includeIfNull: false)
  final String place;

  @JsonKey(name: r'kyc_status', required: true, includeIfNull: false)
  final KycStatus kycStatus;

  /// One line on where it stands, composed by the server.
  @JsonKey(name: r'detail', required: true, includeIfNull: false)
  final String detail;

  /// ISO 8601, UTC.
  @JsonKey(name: r'sent_at', required: true, includeIfNull: false)
  final DateTime sentAt;

  @JsonKey(name: r'commission', required: false, includeIfNull: false)
  final Commission? commission;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is CustomerSummary &&
            runtimeType == other.runtimeType &&
            equals(
              [
                id,
                name,
                systemKw,
                place,
                kycStatus,
                detail,
                sentAt,
                commission,
              ],
              [
                other.id,
                other.name,
                other.systemKw,
                other.place,
                other.kycStatus,
                other.detail,
                other.sentAt,
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
        systemKw,
        place,
        kycStatus,
        detail,
        sentAt,
        commission,
      ]);

  factory CustomerSummary.fromJson(Map<String, dynamic> json) =>
      _$CustomerSummaryFromJson(json);

  Map<String, dynamic> toJson() => _$CustomerSummaryToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
