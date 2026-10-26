//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api_client/src/model/proof_photo.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'proof_slot.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ProofSlot {
  /// Returns a new [ProofSlot] instance.
  ProofSlot({
    required this.id,

    required this.label,

    this.hint,

    this.photo,

    this.retake = false,
  });

  @JsonKey(name: r'id', required: true, includeIfNull: false)
  final String id;

  @JsonKey(name: r'label', required: true, includeIfNull: false)
  final String label;

  @JsonKey(name: r'hint', required: false, includeIfNull: false)
  final String? hint;

  @JsonKey(name: r'photo', required: false, includeIfNull: false)
  final ProofPhoto? photo;

  /// The admin asked for this one again.
  @JsonKey(
    defaultValue: false,
    name: r'retake',
    required: false,
    includeIfNull: false,
  )
  final bool? retake;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is ProofSlot &&
            runtimeType == other.runtimeType &&
            equals(
              [id, label, hint, photo, retake],
              [other.id, other.label, other.hint, other.photo, other.retake],
            );
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^
      mapPropsToHashCode([id, label, hint, photo, retake]);

  factory ProofSlot.fromJson(Map<String, dynamic> json) =>
      _$ProofSlotFromJson(json);

  Map<String, dynamic> toJson() => _$ProofSlotToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
