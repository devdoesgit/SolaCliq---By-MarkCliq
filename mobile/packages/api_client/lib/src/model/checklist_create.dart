//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'checklist_create.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ChecklistCreate {
  /// Returns a new [ChecklistCreate] instance.
  ChecklistCreate({required this.id, required this.text});

  @JsonKey(name: r'id', required: true, includeIfNull: false)
  final String id;

  @JsonKey(name: r'text', required: true, includeIfNull: false)
  final String text;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is ChecklistCreate &&
            runtimeType == other.runtimeType &&
            equals([id, text], [other.id, other.text]);
  }

  @override
  int get hashCode => runtimeType.hashCode ^ mapPropsToHashCode([id, text]);

  factory ChecklistCreate.fromJson(Map<String, dynamic> json) =>
      _$ChecklistCreateFromJson(json);

  Map<String, dynamic> toJson() => _$ChecklistCreateToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
