//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'admin_task_event.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AdminTaskEvent {
  /// Returns a new [AdminTaskEvent] instance.
  AdminTaskEvent({
    required this.kind,

    required this.actorName,

    required this.at,

    this.detail,
  });

  @JsonKey(name: r'kind', required: true, includeIfNull: false)
  final AdminTaskEventKindEnum kind;

  @JsonKey(name: r'actor_name', required: true, includeIfNull: false)
  final String actorName;

  /// ISO 8601, UTC.
  @JsonKey(name: r'at', required: true, includeIfNull: false)
  final DateTime at;

  @JsonKey(name: r'detail', required: false, includeIfNull: false)
  final String? detail;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is AdminTaskEvent &&
            runtimeType == other.runtimeType &&
            equals(
              [kind, actorName, at, detail],
              [other.kind, other.actorName, other.at, other.detail],
            );
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^ mapPropsToHashCode([kind, actorName, at, detail]);

  factory AdminTaskEvent.fromJson(Map<String, dynamic> json) =>
      _$AdminTaskEventFromJson(json);

  Map<String, dynamic> toJson() => _$AdminTaskEventToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum AdminTaskEventKindEnum {
  @JsonValue(r'assigned')
  assigned(r'assigned'),
  @JsonValue(r'photos_uploaded')
  photosUploaded(r'photos_uploaded'),
  @JsonValue(r'submitted')
  submitted(r'submitted'),
  @JsonValue(r'resubmitted')
  resubmitted(r'resubmitted'),
  @JsonValue(r'returned')
  returned(r'returned'),
  @JsonValue(r'approved')
  approved(r'approved'),
  @JsonValue(r'problem_reported')
  problemReported(r'problem_reported'),
  @JsonValue(r'rescheduled')
  rescheduled(r'rescheduled'),
  @JsonValue(r'reassigned')
  reassigned(r'reassigned'),
  @JsonValue(r'cancelled')
  cancelled(r'cancelled'),
  @JsonValue(r'message')
  message(r'message');

  const AdminTaskEventKindEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
