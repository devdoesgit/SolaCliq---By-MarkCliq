//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api_client/src/model/home_status.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'home_row.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class HomeRow {
  /// Returns a new [HomeRow] instance.
  HomeRow({
    this.image,

    this.initials,

    this.glyph,

    required this.id,

    required this.title,

    required this.detail,

    this.status,

    this.action,
  });

  @JsonKey(name: r'image', required: false, includeIfNull: false)
  final String? image;

  @JsonKey(name: r'initials', required: false, includeIfNull: false)
  final String? initials;

  @JsonKey(name: r'glyph', required: false, includeIfNull: false)
  final HomeRowGlyphEnum? glyph;

  @JsonKey(name: r'id', required: true, includeIfNull: false)
  final String id;

  @JsonKey(name: r'title', required: true, includeIfNull: false)
  final String title;

  @JsonKey(name: r'detail', required: true, includeIfNull: false)
  final String detail;

  @JsonKey(name: r'status', required: false, includeIfNull: false)
  final HomeStatus? status;

  /// What tapping it opens: `task` or `customer` (the row's id), `documents` or `track`. None: nothing.
  @JsonKey(name: r'action', required: false, includeIfNull: false)
  final String? action;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is HomeRow &&
            runtimeType == other.runtimeType &&
            equals(
              [image, initials, glyph, id, title, detail, status, action],
              [
                other.image,
                other.initials,
                other.glyph,
                other.id,
                other.title,
                other.detail,
                other.status,
                other.action,
              ],
            );
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^
      mapPropsToHashCode([
        image,
        initials,
        glyph,
        id,
        title,
        detail,
        status,
        action,
      ]);

  factory HomeRow.fromJson(Map<String, dynamic> json) =>
      _$HomeRowFromJson(json);

  Map<String, dynamic> toJson() => _$HomeRowToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum HomeRowGlyphEnum {
  @JsonValue(r'card')
  card(r'card'),
  @JsonValue(r'bill')
  bill(r'bill'),
  @JsonValue(r'passbook')
  passbook(r'passbook'),
  @JsonValue(r'rupee')
  rupee(r'rupee');

  const HomeRowGlyphEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
