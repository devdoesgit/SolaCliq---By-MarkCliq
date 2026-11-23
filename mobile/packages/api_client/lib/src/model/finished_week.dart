//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'finished_week.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class FinishedWeek {
  /// Returns a new [FinishedWeek] instance.
  FinishedWeek({required this.from, required this.count});

  @JsonKey(name: r'from', required: true, includeIfNull: false)
  final String from;

  @JsonKey(name: r'count', required: true, includeIfNull: false)
  final int count;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is FinishedWeek &&
            runtimeType == other.runtimeType &&
            equals([from, count], [other.from, other.count]);
  }

  @override
  int get hashCode => runtimeType.hashCode ^ mapPropsToHashCode([from, count]);

  factory FinishedWeek.fromJson(Map<String, dynamic> json) =>
      _$FinishedWeekFromJson(json);

  Map<String, dynamic> toJson() => _$FinishedWeekToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
