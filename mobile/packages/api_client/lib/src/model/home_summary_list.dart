//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api_client/src/model/home_row.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'home_summary_list.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class HomeSummaryList {
  /// Returns a new [HomeSummaryList] instance.
  HomeSummaryList({this.title, required this.rows});

  @JsonKey(name: r'title', required: false, includeIfNull: false)
  final String? title;

  @JsonKey(name: r'rows', required: true, includeIfNull: false)
  final List<HomeRow> rows;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is HomeSummaryList &&
            runtimeType == other.runtimeType &&
            equals([title, rows], [other.title, other.rows]);
  }

  @override
  int get hashCode => runtimeType.hashCode ^ mapPropsToHashCode([title, rows]);

  factory HomeSummaryList.fromJson(Map<String, dynamic> json) =>
      _$HomeSummaryListFromJson(json);

  Map<String, dynamic> toJson() => _$HomeSummaryListToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
