//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'proof_photo.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ProofPhoto {
  /// Returns a new [ProofPhoto] instance.
  ProofPhoto({
    required this.url,

    required this.takenAt,

    this.lat,

    this.lng,

    this.accuracyM,
  });

  /// Short-lived link to the photo; `asset:<name>` in sample data.
  @JsonKey(name: r'url', required: true, includeIfNull: false)
  final String url;

  /// ISO 8601, UTC.
  @JsonKey(name: r'taken_at', required: true, includeIfNull: false)
  final DateTime takenAt;

  @JsonKey(name: r'lat', required: false, includeIfNull: false)
  final num? lat;

  @JsonKey(name: r'lng', required: false, includeIfNull: false)
  final num? lng;

  @JsonKey(name: r'accuracy_m', required: false, includeIfNull: false)
  final num? accuracyM;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is ProofPhoto &&
            runtimeType == other.runtimeType &&
            equals(
              [url, takenAt, lat, lng, accuracyM],
              [other.url, other.takenAt, other.lat, other.lng, other.accuracyM],
            );
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^
      mapPropsToHashCode([url, takenAt, lat, lng, accuracyM]);

  factory ProofPhoto.fromJson(Map<String, dynamic> json) =>
      _$ProofPhotoFromJson(json);

  Map<String, dynamic> toJson() => _$ProofPhotoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
