//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'task_stage.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class TaskStage {
  /// Returns a new [TaskStage] instance.
  TaskStage({required this.index, required this.count});

  // minimum: 1
  @JsonKey(name: r'index', required: true, includeIfNull: false)
  final int index;

  // minimum: 1
  @JsonKey(name: r'count', required: true, includeIfNull: false)
  final int count;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is TaskStage &&
            runtimeType == other.runtimeType &&
            equals([index, count], [other.index, other.count]);
  }

  @override
  int get hashCode => runtimeType.hashCode ^ mapPropsToHashCode([index, count]);

  factory TaskStage.fromJson(Map<String, dynamic> json) =>
      _$TaskStageFromJson(json);

  Map<String, dynamic> toJson() => _$TaskStageToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
