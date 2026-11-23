//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api_client/src/model/lead_status.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'lead.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class Lead {
  /// Returns a new [Lead] instance.
  Lead({
    required this.id,

    required this.name,

    required this.phone,

    this.city,

    required this.source_,

    required this.status,

    this.agentId,

    this.agentName,

    required this.receivedAt,

    this.email,

    this.pinCode,

    this.monthlyBill,

    this.roofType,

    this.message,

    this.campaign,

    this.pageUrl,

    required this.extra,

    this.note,

    this.updatedAt,
  });

  /// UUIDv7.
  @JsonKey(name: r'id', required: true, includeIfNull: false)
  final String id;

  @JsonKey(name: r'name', required: true, includeIfNull: false)
  final String name;

  /// Ten digits.
  @JsonKey(name: r'phone', required: true, includeIfNull: false)
  final String phone;

  @JsonKey(name: r'city', required: false, includeIfNull: false)
  final String? city;

  @JsonKey(name: r'source', required: true, includeIfNull: false)
  final String source_;

  @JsonKey(name: r'status', required: true, includeIfNull: false)
  final LeadStatus status;

  /// UUIDv7.
  @JsonKey(name: r'agent_id', required: false, includeIfNull: false)
  final String? agentId;

  /// The Sales Agent it's with; both absent when no one has it.
  @JsonKey(name: r'agent_name', required: false, includeIfNull: false)
  final String? agentName;

  /// ISO 8601, UTC.
  @JsonKey(name: r'received_at', required: true, includeIfNull: false)
  final DateTime receivedAt;

  @JsonKey(name: r'email', required: false, includeIfNull: false)
  final String? email;

  @JsonKey(name: r'pin_code', required: false, includeIfNull: false)
  final String? pinCode;

  @JsonKey(name: r'monthly_bill', required: false, includeIfNull: false)
  final String? monthlyBill;

  @JsonKey(name: r'roof_type', required: false, includeIfNull: false)
  final String? roofType;

  @JsonKey(name: r'message', required: false, includeIfNull: false)
  final String? message;

  @JsonKey(name: r'campaign', required: false, includeIfNull: false)
  final String? campaign;

  @JsonKey(name: r'page_url', required: false, includeIfNull: false)
  final String? pageUrl;

  @JsonKey(name: r'extra', required: true, includeIfNull: false)
  final Map<String, String> extra;

  @JsonKey(name: r'note', required: false, includeIfNull: false)
  final String? note;

  /// ISO 8601, UTC.
  @JsonKey(name: r'updated_at', required: false, includeIfNull: false)
  final DateTime? updatedAt;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is Lead &&
            runtimeType == other.runtimeType &&
            equals(
              [
                id,
                name,
                phone,
                city,
                source_,
                status,
                agentId,
                agentName,
                receivedAt,
                email,
                pinCode,
                monthlyBill,
                roofType,
                message,
                campaign,
                pageUrl,
                extra,
                note,
                updatedAt,
              ],
              [
                other.id,
                other.name,
                other.phone,
                other.city,
                other.source_,
                other.status,
                other.agentId,
                other.agentName,
                other.receivedAt,
                other.email,
                other.pinCode,
                other.monthlyBill,
                other.roofType,
                other.message,
                other.campaign,
                other.pageUrl,
                other.extra,
                other.note,
                other.updatedAt,
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
        city,
        source_,
        status,
        agentId,
        agentName,
        receivedAt,
        email,
        pinCode,
        monthlyBill,
        roofType,
        message,
        campaign,
        pageUrl,
        extra,
        note,
        updatedAt,
      ]);

  factory Lead.fromJson(Map<String, dynamic> json) => _$LeadFromJson(json);

  Map<String, dynamic> toJson() => _$LeadToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
