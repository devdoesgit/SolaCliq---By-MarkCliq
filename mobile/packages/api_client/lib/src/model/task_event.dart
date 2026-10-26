//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api_client/src/model/person.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'task_event.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class TaskEvent {
  /// Returns a new [TaskEvent] instance.
  TaskEvent({
    required this.kind,

    required this.actor,

    required this.at,

    this.detail,
  });

  @JsonKey(name: r'kind', required: true, includeIfNull: false)
  final TaskEventKindEnum kind;

  @JsonKey(name: r'actor', required: true, includeIfNull: false)
  final Person actor;

  /// ISO 8601, UTC.
  @JsonKey(name: r'at', required: true, includeIfNull: false)
  final DateTime at;

  /// A line under the event, e.g. the admin's words.
  @JsonKey(name: r'detail', required: false, includeIfNull: false)
  final String? detail;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is TaskEvent &&
            runtimeType == other.runtimeType &&
            equals(
              [kind, actor, at, detail],
              [other.kind, other.actor, other.at, other.detail],
            );
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^ mapPropsToHashCode([kind, actor, at, detail]);

  factory TaskEvent.fromJson(Map<String, dynamic> json) =>
      _$TaskEventFromJson(json);

  Map<String, dynamic> toJson() => _$TaskEventToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum TaskEventKindEnum {
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

  const TaskEventKindEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
