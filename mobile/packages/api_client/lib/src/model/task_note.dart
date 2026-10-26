//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api_client/src/model/person.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'task_note.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class TaskNote {
  /// Returns a new [TaskNote] instance.
  TaskNote({required this.text, required this.by, required this.at});

  @JsonKey(name: r'text', required: true, includeIfNull: false)
  final String text;

  @JsonKey(name: r'by', required: true, includeIfNull: false)
  final Person by;

  /// ISO 8601, UTC.
  @JsonKey(name: r'at', required: true, includeIfNull: false)
  final DateTime at;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is TaskNote &&
            runtimeType == other.runtimeType &&
            equals([text, by, at], [other.text, other.by, other.at]);
  }

  @override
  int get hashCode => runtimeType.hashCode ^ mapPropsToHashCode([text, by, at]);

  factory TaskNote.fromJson(Map<String, dynamic> json) =>
      _$TaskNoteFromJson(json);

  Map<String, dynamic> toJson() => _$TaskNoteToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
