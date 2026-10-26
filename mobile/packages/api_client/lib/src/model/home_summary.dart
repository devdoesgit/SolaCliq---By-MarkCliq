//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api_client/src/model/home_summary_headline.dart';
import 'package:api_client/src/model/home_energy.dart';
import 'package:api_client/src/model/home_tile.dart';
import 'package:api_client/src/model/home_day.dart';
import 'package:api_client/src/model/home_summary_list.dart';
import 'package:api_client/src/model/home_progress.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'home_summary.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class HomeSummary {
  /// Returns a new [HomeSummary] instance.
  HomeSummary({
    this.unreadNotifications,

    required this.eyebrow,

    required this.title,

    this.headline,

    this.week,

    this.energy,

    required this.tiles,

    this.progress,

    required this.list,
  });

  /// Shows a dot on the bell when above zero.
  // minimum: 0
  @JsonKey(name: r'unread_notifications', required: false, includeIfNull: false)
  final int? unreadNotifications;

  @JsonKey(name: r'eyebrow', required: true, includeIfNull: false)
  final String eyebrow;

  @JsonKey(name: r'title', required: true, includeIfNull: false)
  final String title;

  @JsonKey(name: r'headline', required: false, includeIfNull: false)
  final HomeSummaryHeadline? headline;

  @JsonKey(name: r'week', required: false, includeIfNull: false)
  final List<HomeDay>? week;

  @JsonKey(name: r'energy', required: false, includeIfNull: false)
  final HomeEnergy? energy;

  @JsonKey(name: r'tiles', required: true, includeIfNull: false)
  final List<HomeTile> tiles;

  @JsonKey(name: r'progress', required: false, includeIfNull: false)
  final HomeProgress? progress;

  @JsonKey(name: r'list', required: true, includeIfNull: false)
  final HomeSummaryList list;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is HomeSummary &&
            runtimeType == other.runtimeType &&
            equals(
              [
                unreadNotifications,
                eyebrow,
                title,
                headline,
                week,
                energy,
                tiles,
                progress,
                list,
              ],
              [
                other.unreadNotifications,
                other.eyebrow,
                other.title,
                other.headline,
                other.week,
                other.energy,
                other.tiles,
                other.progress,
                other.list,
              ],
            );
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^
      mapPropsToHashCode([
        unreadNotifications,
        eyebrow,
        title,
        headline,
        week,
        energy,
        tiles,
        progress,
        list,
      ]);

  factory HomeSummary.fromJson(Map<String, dynamic> json) =>
      _$HomeSummaryFromJson(json);

  Map<String, dynamic> toJson() => _$HomeSummaryToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
