//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api_client/src/model/commission_totals.dart';
import 'package:api_client/src/model/finished_week.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'admin_overview.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AdminOverview {
  /// Returns a new [AdminOverview] instance.
  AdminOverview({
    required this.today,

    required this.installsRunning,

    required this.byStage,

    required this.collectedThisMonth,

    required this.toCollect,

    required this.finishedByWeek,

    required this.commissions,
  });

  @JsonKey(name: r'today', required: true, includeIfNull: false)
  final String today;

  /// Verified and not handed over.
  @JsonKey(name: r'installs_running', required: true, includeIfNull: false)
  final int installsRunning;

  /// Of those, how many at each stage, first to last.
  @JsonKey(name: r'by_stage', required: true, includeIfNull: false)
  final List<int> byStage;

  /// Amount in paise (₹1 = 100). Never a float.
  @JsonKey(name: r'collected_this_month', required: true, includeIfNull: false)
  final int collectedThisMonth;

  /// Amount in paise (₹1 = 100). Never a float.
  @JsonKey(name: r'to_collect', required: true, includeIfNull: false)
  final int toCollect;

  /// Four runs of 7 days; the last ends today (India).
  @JsonKey(name: r'finished_by_week', required: true, includeIfNull: false)
  final List<FinishedWeek> finishedByWeek;

  @JsonKey(name: r'commissions', required: true, includeIfNull: false)
  final CommissionTotals commissions;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is AdminOverview &&
            runtimeType == other.runtimeType &&
            equals(
              [
                today,
                installsRunning,
                byStage,
                collectedThisMonth,
                toCollect,
                finishedByWeek,
                commissions,
              ],
              [
                other.today,
                other.installsRunning,
                other.byStage,
                other.collectedThisMonth,
                other.toCollect,
                other.finishedByWeek,
                other.commissions,
              ],
            );
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^
      mapPropsToHashCode([
        today,
        installsRunning,
        byStage,
        collectedThisMonth,
        toCollect,
        finishedByWeek,
        commissions,
      ]);

  factory AdminOverview.fromJson(Map<String, dynamic> json) =>
      _$AdminOverviewFromJson(json);

  Map<String, dynamic> toJson() => _$AdminOverviewToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
