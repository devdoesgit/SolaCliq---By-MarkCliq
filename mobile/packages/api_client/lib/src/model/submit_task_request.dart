//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'submit_task_request.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class SubmitTaskRequest {
  /// Returns a new [SubmitTaskRequest] instance.
  SubmitTaskRequest({this.note});

  /// Optional note for the admin.
  @JsonKey(name: r'note', required: false, includeIfNull: false)
  final String? note;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is SubmitTaskRequest &&
            runtimeType == other.runtimeType &&
            equals([note], [other.note]);
  }

  @override
  int get hashCode => runtimeType.hashCode ^ mapPropsToHashCode([note]);

  factory SubmitTaskRequest.fromJson(Map<String, dynamic> json) =>
      _$SubmitTaskRequestFromJson(json);

  Map<String, dynamic> toJson() => _$SubmitTaskRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
