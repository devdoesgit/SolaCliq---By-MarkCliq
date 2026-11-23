//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'stage_template_set.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class StageTemplateSet {
  /// Returns a new [StageTemplateSet] instance.
  StageTemplateSet({
    required this.name,

    required this.checklist,

    required this.photos,
  });

  @JsonKey(name: r'name', required: true, includeIfNull: false)
  final String name;

  @JsonKey(name: r'checklist', required: true, includeIfNull: false)
  final List<String> checklist;

  @JsonKey(name: r'photos', required: true, includeIfNull: false)
  final List<String> photos;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is StageTemplateSet &&
            runtimeType == other.runtimeType &&
            equals(
              [name, checklist, photos],
              [other.name, other.checklist, other.photos],
            );
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^ mapPropsToHashCode([name, checklist, photos]);

  factory StageTemplateSet.fromJson(Map<String, dynamic> json) =>
      _$StageTemplateSetFromJson(json);

  Map<String, dynamic> toJson() => _$StageTemplateSetToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
