//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api_client/src/model/lead_status.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'lead_summary.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class LeadSummary {
  /// Returns a new [LeadSummary] instance.
  LeadSummary({
    required this.id,

    required this.name,

    required this.phone,

    this.city,

    required this.source_,

    required this.status,

    this.agentId,

    this.agentName,

    required this.receivedAt,
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

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is LeadSummary &&
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
      ]);

  factory LeadSummary.fromJson(Map<String, dynamic> json) =>
      _$LeadSummaryFromJson(json);

  Map<String, dynamic> toJson() => _$LeadSummaryToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
