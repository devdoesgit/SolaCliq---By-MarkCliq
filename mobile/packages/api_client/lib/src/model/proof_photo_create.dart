//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'proof_photo_create.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ProofPhotoCreate {
  /// Returns a new [ProofPhotoCreate] instance.
  ProofPhotoCreate({
    required this.slotId,

    required this.uploadId,

    required this.takenAt,

    required this.lat,

    required this.lng,

    required this.accuracyM,

    this.mockedLocation = false,
  });

  @JsonKey(name: r'slot_id', required: true, includeIfNull: false)
  final String slotId;

  /// UUIDv7.
  @JsonKey(name: r'upload_id', required: true, includeIfNull: false)
  final String uploadId;

  /// ISO 8601, UTC.
  @JsonKey(name: r'taken_at', required: true, includeIfNull: false)
  final DateTime takenAt;

  @JsonKey(name: r'lat', required: true, includeIfNull: false)
  final num lat;

  @JsonKey(name: r'lng', required: true, includeIfNull: false)
  final num lng;

  // minimum: 0
  @JsonKey(name: r'accuracy_m', required: true, includeIfNull: false)
  final num accuracyM;

  /// The phone reported a mocked (fake) location.
  @JsonKey(
    defaultValue: false,
    name: r'mocked_location',
    required: false,
    includeIfNull: false,
  )
  final bool? mockedLocation;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is ProofPhotoCreate &&
            runtimeType == other.runtimeType &&
            equals(
              [slotId, uploadId, takenAt, lat, lng, accuracyM, mockedLocation],
              [
                other.slotId,
                other.uploadId,
                other.takenAt,
                other.lat,
                other.lng,
                other.accuracyM,
                other.mockedLocation,
              ],
            );
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^
      mapPropsToHashCode([
        slotId,
        uploadId,
        takenAt,
        lat,
        lng,
        accuracyM,
        mockedLocation,
      ]);

  factory ProofPhotoCreate.fromJson(Map<String, dynamic> json) =>
      _$ProofPhotoCreateFromJson(json);

  Map<String, dynamic> toJson() => _$ProofPhotoCreateToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
