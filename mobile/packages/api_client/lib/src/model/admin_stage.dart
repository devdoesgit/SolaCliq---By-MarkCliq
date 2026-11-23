//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'admin_stage.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AdminStage {
  /// Returns a new [AdminStage] instance.
  AdminStage({required this.index, required this.count, required this.name});

  @JsonKey(name: r'index', required: true, includeIfNull: false)
  final int index;

  @JsonKey(name: r'count', required: true, includeIfNull: false)
  final int count;

  @JsonKey(name: r'name', required: true, includeIfNull: false)
  final String name;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is AdminStage &&
            runtimeType == other.runtimeType &&
            equals(
              [index, count, name],
              [other.index, other.count, other.name],
            );
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^ mapPropsToHashCode([index, count, name]);

  factory AdminStage.fromJson(Map<String, dynamic> json) =>
      _$AdminStageFromJson(json);

  Map<String, dynamic> toJson() => _$AdminStageToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
