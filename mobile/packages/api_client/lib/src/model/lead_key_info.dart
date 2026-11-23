//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'lead_key_info.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class LeadKeyInfo {
  /// Returns a new [LeadKeyInfo] instance.
  LeadKeyInfo({required this.set_, this.madeAt, this.lastUsedAt});

  @JsonKey(name: r'set', required: true, includeIfNull: false)
  final bool set_;

  /// ISO 8601, UTC.
  @JsonKey(name: r'made_at', required: false, includeIfNull: false)
  final DateTime? madeAt;

  /// ISO 8601, UTC.
  @JsonKey(name: r'last_used_at', required: false, includeIfNull: false)
  final DateTime? lastUsedAt;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is LeadKeyInfo &&
            runtimeType == other.runtimeType &&
            equals(
              [set_, madeAt, lastUsedAt],
              [other.set_, other.madeAt, other.lastUsedAt],
            );
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^ mapPropsToHashCode([set_, madeAt, lastUsedAt]);

  factory LeadKeyInfo.fromJson(Map<String, dynamic> json) =>
      _$LeadKeyInfoFromJson(json);

  Map<String, dynamic> toJson() => _$LeadKeyInfoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
