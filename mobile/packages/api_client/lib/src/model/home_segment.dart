//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api_client/src/model/home_tone.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'home_segment.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class HomeSegment {
  /// Returns a new [HomeSegment] instance.
  HomeSegment({required this.weight, required this.tone, this.label});

  // minimum: 1
  @JsonKey(name: r'weight', required: true, includeIfNull: false)
  final int weight;

  @JsonKey(name: r'tone', required: true, includeIfNull: false)
  final HomeTone tone;

  /// For the legend.
  @JsonKey(name: r'label', required: false, includeIfNull: false)
  final String? label;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is HomeSegment &&
            runtimeType == other.runtimeType &&
            equals(
              [weight, tone, label],
              [other.weight, other.tone, other.label],
            );
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^ mapPropsToHashCode([weight, tone, label]);

  factory HomeSegment.fromJson(Map<String, dynamic> json) =>
      _$HomeSegmentFromJson(json);

  Map<String, dynamic> toJson() => _$HomeSegmentToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
