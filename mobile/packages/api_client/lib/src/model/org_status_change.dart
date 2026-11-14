//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'org_status_change.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class OrgStatusChange {
  /// Returns a new [OrgStatusChange] instance.
  OrgStatusChange({required this.status, this.note});

  @JsonKey(name: r'status', required: true, includeIfNull: false)
  final OrgStatusChangeStatusEnum status;

  /// Required to reject; emailed to the owner.
  @JsonKey(name: r'note', required: false, includeIfNull: false)
  final String? note;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is OrgStatusChange &&
            runtimeType == other.runtimeType &&
            equals([status, note], [other.status, other.note]);
  }

  @override
  int get hashCode => runtimeType.hashCode ^ mapPropsToHashCode([status, note]);

  factory OrgStatusChange.fromJson(Map<String, dynamic> json) =>
      _$OrgStatusChangeFromJson(json);

  Map<String, dynamic> toJson() => _$OrgStatusChangeToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum OrgStatusChangeStatusEnum {
  @JsonValue(r'active')
  active(r'active'),
  @JsonValue(r'rejected')
  rejected(r'rejected'),
  @JsonValue(r'suspended')
  suspended(r'suspended');

  const OrgStatusChangeStatusEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
