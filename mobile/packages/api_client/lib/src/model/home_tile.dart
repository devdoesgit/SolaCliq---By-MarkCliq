//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api_client/src/model/home_visual.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'home_tile.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class HomeTile {
  /// Returns a new [HomeTile] instance.
  HomeTile({
    required this.label,

    required this.value,

    this.icon,

    this.footer,

    this.dark = false,

    this.avatars,

    this.action,
  });

  @JsonKey(name: r'label', required: true, includeIfNull: false)
  final String label;

  @JsonKey(name: r'value', required: true, includeIfNull: false)
  final String value;

  /// An icon name from the app's set.
  @JsonKey(name: r'icon', required: false, includeIfNull: false)
  final HomeTileIconEnum? icon;

  @JsonKey(name: r'footer', required: false, includeIfNull: false)
  final String? footer;

  @JsonKey(
    defaultValue: false,
    name: r'dark',
    required: false,
    includeIfNull: false,
  )
  final bool? dark;

  @JsonKey(name: r'avatars', required: false, includeIfNull: false)
  final List<HomeVisual>? avatars;

  /// What tapping it opens, if anything.
  @JsonKey(name: r'action', required: false, includeIfNull: false)
  final String? action;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is HomeTile &&
            runtimeType == other.runtimeType &&
            equals(
              [label, value, icon, footer, dark, avatars, action],
              [
                other.label,
                other.value,
                other.icon,
                other.footer,
                other.dark,
                other.avatars,
                other.action,
              ],
            );
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^
      mapPropsToHashCode([label, value, icon, footer, dark, avatars, action]);

  factory HomeTile.fromJson(Map<String, dynamic> json) =>
      _$HomeTileFromJson(json);

  Map<String, dynamic> toJson() => _$HomeTileToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

/// An icon name from the app's set.
enum HomeTileIconEnum {
  @JsonValue(r'camera')
  camera(r'camera'),
  @JsonValue(r'receipt')
  receipt(r'receipt'),
  @JsonValue(r'alarm')
  alarm(r'alarm'),
  @JsonValue(r'hourglass')
  hourglass(r'hourglass'),
  @JsonValue(r'shield')
  shield(r'shield'),
  @JsonValue(r'wallet')
  wallet(r'wallet'),
  @JsonValue(r'sun')
  sun(r'sun'),
  @JsonValue(r'users')
  users(r'users');

  const HomeTileIconEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
