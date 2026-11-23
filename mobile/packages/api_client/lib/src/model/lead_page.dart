//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api_client/src/model/page_info.dart';
import 'package:api_client/src/model/lead_summary.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'lead_page.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class LeadPage {
  /// Returns a new [LeadPage] instance.
  LeadPage({required this.items, required this.page});

  @JsonKey(name: r'items', required: true, includeIfNull: false)
  final List<LeadSummary> items;

  @JsonKey(name: r'page', required: true, includeIfNull: false)
  final PageInfo page;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is LeadPage &&
            runtimeType == other.runtimeType &&
            equals([items, page], [other.items, other.page]);
  }

  @override
  int get hashCode => runtimeType.hashCode ^ mapPropsToHashCode([items, page]);

  factory LeadPage.fromJson(Map<String, dynamic> json) =>
      _$LeadPageFromJson(json);

  Map<String, dynamic> toJson() => _$LeadPageToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
