//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api_client/src/model/admin_task_summary.dart';
import 'package:api_client/src/model/page_info.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'admin_task_page.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AdminTaskPage {
  /// Returns a new [AdminTaskPage] instance.
  AdminTaskPage({required this.items, required this.page});

  @JsonKey(name: r'items', required: true, includeIfNull: false)
  final List<AdminTaskSummary> items;

  @JsonKey(name: r'page', required: true, includeIfNull: false)
  final PageInfo page;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is AdminTaskPage &&
            runtimeType == other.runtimeType &&
            equals([items, page], [other.items, other.page]);
  }

  @override
  int get hashCode => runtimeType.hashCode ^ mapPropsToHashCode([items, page]);

  factory AdminTaskPage.fromJson(Map<String, dynamic> json) =>
      _$AdminTaskPageFromJson(json);

  Map<String, dynamic> toJson() => _$AdminTaskPageToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
