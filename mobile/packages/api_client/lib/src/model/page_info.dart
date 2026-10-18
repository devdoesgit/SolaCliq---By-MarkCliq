//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'page_info.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PageInfo {
  /// Returns a new [PageInfo] instance.
  PageInfo({required this.nextCursor});

  /// Pass as `cursor` for the next page; null on the last page.
  @JsonKey(name: r'next_cursor', required: true, includeIfNull: true)
  final String? nextCursor;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is PageInfo &&
            runtimeType == other.runtimeType &&
            equals([nextCursor], [other.nextCursor]);
  }

  @override
  int get hashCode => runtimeType.hashCode ^ mapPropsToHashCode([nextCursor]);

  factory PageInfo.fromJson(Map<String, dynamic> json) =>
      _$PageInfoFromJson(json);

  Map<String, dynamic> toJson() => _$PageInfoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
