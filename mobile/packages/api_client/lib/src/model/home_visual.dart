//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'home_visual.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class HomeVisual {
  /// Returns a new [HomeVisual] instance.
  HomeVisual({this.image, this.initials, this.glyph});

  @JsonKey(name: r'image', required: false, includeIfNull: false)
  final String? image;

  @JsonKey(name: r'initials', required: false, includeIfNull: false)
  final String? initials;

  @JsonKey(name: r'glyph', required: false, includeIfNull: false)
  final HomeVisualGlyphEnum? glyph;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is HomeVisual &&
            runtimeType == other.runtimeType &&
            equals(
              [image, initials, glyph],
              [other.image, other.initials, other.glyph],
            );
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^ mapPropsToHashCode([image, initials, glyph]);

  factory HomeVisual.fromJson(Map<String, dynamic> json) =>
      _$HomeVisualFromJson(json);

  Map<String, dynamic> toJson() => _$HomeVisualToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum HomeVisualGlyphEnum {
  @JsonValue(r'card')
  card(r'card'),
  @JsonValue(r'bill')
  bill(r'bill'),
  @JsonValue(r'passbook')
  passbook(r'passbook'),
  @JsonValue(r'rupee')
  rupee(r'rupee');

  const HomeVisualGlyphEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
