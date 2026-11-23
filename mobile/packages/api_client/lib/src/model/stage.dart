//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'stage.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class Stage {
  /// Returns a new [Stage] instance.
  Stage({
    required this.index,

    required this.name,

    required this.checklist,

    required this.photos,
  });

  // minimum: 1
  // maximum: 7
  @JsonKey(name: r'index', required: true, includeIfNull: false)
  final int index;

  @JsonKey(name: r'name', required: true, includeIfNull: false)
  final String name;

  /// What a new task at this stage asks to tick off.
  @JsonKey(name: r'checklist', required: true, includeIfNull: false)
  final List<String> checklist;

  /// The photos a new task at this stage asks for.
  @JsonKey(name: r'photos', required: true, includeIfNull: false)
  final List<String> photos;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is Stage &&
            runtimeType == other.runtimeType &&
            equals(
              [index, name, checklist, photos],
              [other.index, other.name, other.checklist, other.photos],
            );
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^
      mapPropsToHashCode([index, name, checklist, photos]);

  factory Stage.fromJson(Map<String, dynamic> json) => _$StageFromJson(json);

  Map<String, dynamic> toJson() => _$StageToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
