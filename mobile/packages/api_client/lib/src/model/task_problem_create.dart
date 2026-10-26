//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api_client/src/model/task_problem_reason.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'task_problem_create.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class TaskProblemCreate {
  /// Returns a new [TaskProblemCreate] instance.
  TaskProblemCreate({required this.reason, required this.note, this.uploadId});

  @JsonKey(name: r'reason', required: true, includeIfNull: false)
  final TaskProblemReason reason;

  @JsonKey(name: r'note', required: true, includeIfNull: false)
  final String note;

  /// An optional photo (purpose `proof`).
  @JsonKey(name: r'upload_id', required: false, includeIfNull: false)
  final String? uploadId;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is TaskProblemCreate &&
            runtimeType == other.runtimeType &&
            equals(
              [reason, note, uploadId],
              [other.reason, other.note, other.uploadId],
            );
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^ mapPropsToHashCode([reason, note, uploadId]);

  factory TaskProblemCreate.fromJson(Map<String, dynamic> json) =>
      _$TaskProblemCreateFromJson(json);

  Map<String, dynamic> toJson() => _$TaskProblemCreateToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
