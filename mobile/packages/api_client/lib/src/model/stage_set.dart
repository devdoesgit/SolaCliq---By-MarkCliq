//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'stage_set.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class StageSet {
  /// Returns a new [StageSet] instance.
  StageSet({required this.stageIndex});

  // minimum: 1
  // maximum: 7
  @JsonKey(name: r'stage_index', required: true, includeIfNull: false)
  final int stageIndex;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is StageSet &&
            runtimeType == other.runtimeType &&
            equals([stageIndex], [other.stageIndex]);
  }

  @override
  int get hashCode => runtimeType.hashCode ^ mapPropsToHashCode([stageIndex]);

  factory StageSet.fromJson(Map<String, dynamic> json) =>
      _$StageSetFromJson(json);

  Map<String, dynamic> toJson() => _$StageSetToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
