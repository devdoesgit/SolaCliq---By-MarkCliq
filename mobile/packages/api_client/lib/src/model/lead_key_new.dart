//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'lead_key_new.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class LeadKeyNew {
  /// Returns a new [LeadKeyNew] instance.
  LeadKeyNew({required this.key, required this.madeAt});

  /// Shown once. Keep it on the landing page's server.
  @JsonKey(name: r'key', required: true, includeIfNull: false)
  final String key;

  /// ISO 8601, UTC.
  @JsonKey(name: r'made_at', required: true, includeIfNull: false)
  final DateTime madeAt;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is LeadKeyNew &&
            runtimeType == other.runtimeType &&
            equals([key, madeAt], [other.key, other.madeAt]);
  }

  @override
  int get hashCode => runtimeType.hashCode ^ mapPropsToHashCode([key, madeAt]);

  factory LeadKeyNew.fromJson(Map<String, dynamic> json) =>
      _$LeadKeyNewFromJson(json);

  Map<String, dynamic> toJson() => _$LeadKeyNewToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
