//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'worker_stats.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class WorkerStats {
  /// Returns a new [WorkerStats] instance.
  WorkerStats({
    required this.tasksThisMonth,

    required this.returnedThisMonth,

    required this.avgMinutesOnSite,
  });

  @JsonKey(name: r'tasks_this_month', required: true, includeIfNull: false)
  final int tasksThisMonth;

  @JsonKey(name: r'returned_this_month', required: true, includeIfNull: false)
  final int returnedThisMonth;

  @JsonKey(name: r'avg_minutes_on_site', required: true, includeIfNull: false)
  final int avgMinutesOnSite;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is WorkerStats &&
            runtimeType == other.runtimeType &&
            equals(
              [tasksThisMonth, returnedThisMonth, avgMinutesOnSite],
              [
                other.tasksThisMonth,
                other.returnedThisMonth,
                other.avgMinutesOnSite,
              ],
            );
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^
      mapPropsToHashCode([tasksThisMonth, returnedThisMonth, avgMinutesOnSite]);

  factory WorkerStats.fromJson(Map<String, dynamic> json) =>
      _$WorkerStatsFromJson(json);

  Map<String, dynamic> toJson() => _$WorkerStatsToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
