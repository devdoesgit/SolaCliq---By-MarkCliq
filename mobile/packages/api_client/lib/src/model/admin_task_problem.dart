//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api_client/src/model/task_problem_reason.dart';
import 'package:api_client/src/model/admin_file.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'admin_task_problem.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AdminTaskProblem {
  /// Returns a new [AdminTaskProblem] instance.
  AdminTaskProblem({
    required this.reason,

    required this.note,

    required this.at,

    this.photo,
  });

  @JsonKey(name: r'reason', required: true, includeIfNull: false)
  final TaskProblemReason reason;

  @JsonKey(name: r'note', required: true, includeIfNull: false)
  final String note;

  /// ISO 8601, UTC.
  @JsonKey(name: r'at', required: true, includeIfNull: false)
  final DateTime at;

  @JsonKey(name: r'photo', required: false, includeIfNull: false)
  final AdminFile? photo;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is AdminTaskProblem &&
            runtimeType == other.runtimeType &&
            equals(
              [reason, note, at, photo],
              [other.reason, other.note, other.at, other.photo],
            );
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^ mapPropsToHashCode([reason, note, at, photo]);

  factory AdminTaskProblem.fromJson(Map<String, dynamic> json) =>
      _$AdminTaskProblemFromJson(json);

  Map<String, dynamic> toJson() => _$AdminTaskProblemToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
