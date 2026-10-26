//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'install_stage.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class InstallStage {
  /// Returns a new [InstallStage] instance.
  InstallStage({required this.name, this.detail, required this.status});

  @JsonKey(name: r'name', required: true, includeIfNull: false)
  final String name;

  @JsonKey(name: r'detail', required: false, includeIfNull: false)
  final String? detail;

  @JsonKey(name: r'status', required: true, includeIfNull: false)
  final InstallStageStatusEnum status;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is InstallStage &&
            runtimeType == other.runtimeType &&
            equals(
              [name, detail, status],
              [other.name, other.detail, other.status],
            );
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^ mapPropsToHashCode([name, detail, status]);

  factory InstallStage.fromJson(Map<String, dynamic> json) =>
      _$InstallStageFromJson(json);

  Map<String, dynamic> toJson() => _$InstallStageToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum InstallStageStatusEnum {
  @JsonValue(r'done')
  done(r'done'),
  @JsonValue(r'next')
  next(r'next'),
  @JsonValue(r'upcoming')
  upcoming(r'upcoming');

  const InstallStageStatusEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
