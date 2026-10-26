//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api_client/src/model/task_problem_reason.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'task_problem.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class TaskProblem {
  /// Returns a new [TaskProblem] instance.
  TaskProblem({required this.reason, required this.note, required this.at});

  @JsonKey(name: r'reason', required: true, includeIfNull: false)
  final TaskProblemReason reason;

  @JsonKey(name: r'note', required: true, includeIfNull: false)
  final String note;

  /// ISO 8601, UTC.
  @JsonKey(name: r'at', required: true, includeIfNull: false)
  final DateTime at;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is TaskProblem &&
            runtimeType == other.runtimeType &&
            equals([reason, note, at], [other.reason, other.note, other.at]);
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^ mapPropsToHashCode([reason, note, at]);

  factory TaskProblem.fromJson(Map<String, dynamic> json) =>
      _$TaskProblemFromJson(json);

  Map<String, dynamic> toJson() => _$TaskProblemToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
