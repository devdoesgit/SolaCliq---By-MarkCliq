//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'task_schedule.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class TaskSchedule {
  /// Returns a new [TaskSchedule] instance.
  TaskSchedule({this.assigneeId, required this.dueAt});

  @JsonKey(name: r'assignee_id', required: false, includeIfNull: false)
  final String? assigneeId;

  @JsonKey(name: r'due_at', required: true, includeIfNull: false)
  final DateTime dueAt;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is TaskSchedule &&
            runtimeType == other.runtimeType &&
            equals([assigneeId, dueAt], [other.assigneeId, other.dueAt]);
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^ mapPropsToHashCode([assigneeId, dueAt]);

  factory TaskSchedule.fromJson(Map<String, dynamic> json) =>
      _$TaskScheduleFromJson(json);

  Map<String, dynamic> toJson() => _$TaskScheduleToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
