//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'checklist_item.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ChecklistItem {
  /// Returns a new [ChecklistItem] instance.
  ChecklistItem({required this.id, required this.text, required this.done});

  @JsonKey(name: r'id', required: true, includeIfNull: false)
  final String id;

  @JsonKey(name: r'text', required: true, includeIfNull: false)
  final String text;

  @JsonKey(name: r'done', required: true, includeIfNull: false)
  final bool done;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is ChecklistItem &&
            runtimeType == other.runtimeType &&
            equals([id, text, done], [other.id, other.text, other.done]);
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^ mapPropsToHashCode([id, text, done]);

  factory ChecklistItem.fromJson(Map<String, dynamic> json) =>
      _$ChecklistItemFromJson(json);

  Map<String, dynamic> toJson() => _$ChecklistItemToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
