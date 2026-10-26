//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'home_summary_headline.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class HomeSummaryHeadline {
  /// Returns a new [HomeSummaryHeadline] instance.
  HomeSummaryHeadline({required this.value, required this.label, this.detail});

  @JsonKey(name: r'value', required: true, includeIfNull: false)
  final String value;

  @JsonKey(name: r'label', required: true, includeIfNull: false)
  final String label;

  @JsonKey(name: r'detail', required: false, includeIfNull: false)
  final String? detail;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is HomeSummaryHeadline &&
            runtimeType == other.runtimeType &&
            equals(
              [value, label, detail],
              [other.value, other.label, other.detail],
            );
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^ mapPropsToHashCode([value, label, detail]);

  factory HomeSummaryHeadline.fromJson(Map<String, dynamic> json) =>
      _$HomeSummaryHeadlineFromJson(json);

  Map<String, dynamic> toJson() => _$HomeSummaryHeadlineToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
