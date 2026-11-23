//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api_client/src/model/stage.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'stage_list.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class StageList {
  /// Returns a new [StageList] instance.
  StageList({required this.stages});

  /// All 7, in order.
  @JsonKey(name: r'stages', required: true, includeIfNull: false)
  final List<Stage> stages;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is StageList &&
            runtimeType == other.runtimeType &&
            equals([stages], [other.stages]);
  }

  @override
  int get hashCode => runtimeType.hashCode ^ mapPropsToHashCode([stages]);

  factory StageList.fromJson(Map<String, dynamic> json) =>
      _$StageListFromJson(json);

  Map<String, dynamic> toJson() => _$StageListToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
