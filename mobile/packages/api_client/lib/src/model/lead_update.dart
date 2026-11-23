//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api_client/src/model/lead_status.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'lead_update.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class LeadUpdate {
  /// Returns a new [LeadUpdate] instance.
  LeadUpdate({this.status, this.note, this.agentId});

  @JsonKey(name: r'status', required: false, includeIfNull: false)
  final LeadStatus? status;

  @JsonKey(name: r'note', required: false, includeIfNull: false)
  final String? note;

  /// Admins only. Null takes the lead back.
  @JsonKey(name: r'agent_id', required: false, includeIfNull: false)
  final String? agentId;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is LeadUpdate &&
            runtimeType == other.runtimeType &&
            equals(
              [status, note, agentId],
              [other.status, other.note, other.agentId],
            );
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^ mapPropsToHashCode([status, note, agentId]);

  factory LeadUpdate.fromJson(Map<String, dynamic> json) =>
      _$LeadUpdateFromJson(json);

  Map<String, dynamic> toJson() => _$LeadUpdateToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
