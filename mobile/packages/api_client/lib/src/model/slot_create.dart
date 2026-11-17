//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'slot_create.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class SlotCreate {
  /// Returns a new [SlotCreate] instance.
  SlotCreate({this.hint, required this.id, required this.label});

  @JsonKey(name: r'hint', required: false, includeIfNull: false)
  final String? hint;

  @JsonKey(name: r'id', required: true, includeIfNull: false)
  final String id;

  @JsonKey(name: r'label', required: true, includeIfNull: false)
  final String label;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is SlotCreate &&
            runtimeType == other.runtimeType &&
            equals([hint, id, label], [other.hint, other.id, other.label]);
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^ mapPropsToHashCode([hint, id, label]);

  factory SlotCreate.fromJson(Map<String, dynamic> json) =>
      _$SlotCreateFromJson(json);

  Map<String, dynamic> toJson() => _$SlotCreateToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
