//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'task_return.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class TaskReturn {
  /// Returns a new [TaskReturn] instance.
  TaskReturn({required this.note, this.retake});

  @JsonKey(name: r'note', required: true, includeIfNull: false)
  final String note;

  @JsonKey(name: r'retake', required: false, includeIfNull: false)
  final List<String>? retake;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is TaskReturn &&
            runtimeType == other.runtimeType &&
            equals([note, retake], [other.note, other.retake]);
  }

  @override
  int get hashCode => runtimeType.hashCode ^ mapPropsToHashCode([note, retake]);

  factory TaskReturn.fromJson(Map<String, dynamic> json) =>
      _$TaskReturnFromJson(json);

  Map<String, dynamic> toJson() => _$TaskReturnToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
