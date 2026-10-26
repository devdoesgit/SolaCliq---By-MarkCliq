//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api_client/src/model/task_event.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'task_history.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class TaskHistory {
  /// Returns a new [TaskHistory] instance.
  TaskHistory({required this.events});

  @JsonKey(name: r'events', required: true, includeIfNull: false)
  final List<TaskEvent> events;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is TaskHistory &&
            runtimeType == other.runtimeType &&
            equals([events], [other.events]);
  }

  @override
  int get hashCode => runtimeType.hashCode ^ mapPropsToHashCode([events]);

  factory TaskHistory.fromJson(Map<String, dynamic> json) =>
      _$TaskHistoryFromJson(json);

  Map<String, dynamic> toJson() => _$TaskHistoryToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
