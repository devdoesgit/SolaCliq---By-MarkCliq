//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api_client/src/model/person.dart';
import 'package:api_client/src/model/task_summary.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'task_approved.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class TaskApproved {
  /// Returns a new [TaskApproved] instance.
  TaskApproved({required this.by, required this.at, this.nextTask});

  @JsonKey(name: r'by', required: true, includeIfNull: false)
  final Person by;

  /// ISO 8601, UTC.
  @JsonKey(name: r'at', required: true, includeIfNull: false)
  final DateTime at;

  @JsonKey(name: r'next_task', required: false, includeIfNull: false)
  final TaskSummary? nextTask;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is TaskApproved &&
            runtimeType == other.runtimeType &&
            equals([by, at, nextTask], [other.by, other.at, other.nextTask]);
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^ mapPropsToHashCode([by, at, nextTask]);

  factory TaskApproved.fromJson(Map<String, dynamic> json) =>
      _$TaskApprovedFromJson(json);

  Map<String, dynamic> toJson() => _$TaskApprovedToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
