//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api_client/src/model/install_next_visit_person.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'install_next_visit.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class InstallNextVisit {
  /// Returns a new [InstallNextVisit] instance.
  InstallNextVisit({
    required this.title,

    required this.startsAt,

    this.endsAt,

    required this.person,
  });

  @JsonKey(name: r'title', required: true, includeIfNull: false)
  final String title;

  /// ISO 8601, UTC.
  @JsonKey(name: r'starts_at', required: true, includeIfNull: false)
  final DateTime startsAt;

  /// ISO 8601, UTC.
  @JsonKey(name: r'ends_at', required: false, includeIfNull: false)
  final DateTime? endsAt;

  @JsonKey(name: r'person', required: true, includeIfNull: false)
  final InstallNextVisitPerson person;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is InstallNextVisit &&
            runtimeType == other.runtimeType &&
            equals(
              [title, startsAt, endsAt, person],
              [other.title, other.startsAt, other.endsAt, other.person],
            );
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^
      mapPropsToHashCode([title, startsAt, endsAt, person]);

  factory InstallNextVisit.fromJson(Map<String, dynamic> json) =>
      _$InstallNextVisitFromJson(json);

  Map<String, dynamic> toJson() => _$InstallNextVisitToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
