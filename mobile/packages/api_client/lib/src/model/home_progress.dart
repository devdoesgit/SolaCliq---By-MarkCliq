//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api_client/src/model/home_segment.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'home_progress.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class HomeProgress {
  /// Returns a new [HomeProgress] instance.
  HomeProgress({
    required this.label,

    this.trailing,

    required this.segments,

    this.stages,

    this.legend = false,
  });

  @JsonKey(name: r'label', required: true, includeIfNull: false)
  final String label;

  @JsonKey(name: r'trailing', required: false, includeIfNull: false)
  final String? trailing;

  @JsonKey(name: r'segments', required: true, includeIfNull: false)
  final List<HomeSegment> segments;

  /// Names spread under the bar.
  @JsonKey(name: r'stages', required: false, includeIfNull: false)
  final List<String>? stages;

  /// Shows each segment's label with a dot under the bar.
  @JsonKey(
    defaultValue: false,
    name: r'legend',
    required: false,
    includeIfNull: false,
  )
  final bool? legend;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is HomeProgress &&
            runtimeType == other.runtimeType &&
            equals(
              [label, trailing, segments, stages, legend],
              [
                other.label,
                other.trailing,
                other.segments,
                other.stages,
                other.legend,
              ],
            );
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^
      mapPropsToHashCode([label, trailing, segments, stages, legend]);

  factory HomeProgress.fromJson(Map<String, dynamic> json) =>
      _$HomeProgressFromJson(json);

  Map<String, dynamic> toJson() => _$HomeProgressToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
