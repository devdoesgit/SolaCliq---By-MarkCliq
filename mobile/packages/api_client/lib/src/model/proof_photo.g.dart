// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'proof_photo.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ProofPhotoCWProxy {
  ProofPhoto url(String url);

  ProofPhoto takenAt(DateTime takenAt);

  ProofPhoto lat(num? lat);

  ProofPhoto lng(num? lng);

  ProofPhoto accuracyM(num? accuracyM);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ProofPhoto(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ProofPhoto(...).copyWith(id: 12, name: "My name")
  /// ````
  ProofPhoto call({
    String url,
    DateTime takenAt,
    num? lat,
    num? lng,
    num? accuracyM,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfProofPhoto.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfProofPhoto.copyWith.fieldName(...)`
class _$ProofPhotoCWProxyImpl implements _$ProofPhotoCWProxy {
  const _$ProofPhotoCWProxyImpl(this._value);

  final ProofPhoto _value;

  @override
  ProofPhoto url(String url) => this(url: url);

  @override
  ProofPhoto takenAt(DateTime takenAt) => this(takenAt: takenAt);

  @override
  ProofPhoto lat(num? lat) => this(lat: lat);

  @override
  ProofPhoto lng(num? lng) => this(lng: lng);

  @override
  ProofPhoto accuracyM(num? accuracyM) => this(accuracyM: accuracyM);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ProofPhoto(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ProofPhoto(...).copyWith(id: 12, name: "My name")
  /// ````
  ProofPhoto call({
    Object? url = const $CopyWithPlaceholder(),
    Object? takenAt = const $CopyWithPlaceholder(),
    Object? lat = const $CopyWithPlaceholder(),
    Object? lng = const $CopyWithPlaceholder(),
    Object? accuracyM = const $CopyWithPlaceholder(),
  }) {
    return ProofPhoto(
      url: url == const $CopyWithPlaceholder()
          ? _value.url
          // ignore: cast_nullable_to_non_nullable
          : url as String,
      takenAt: takenAt == const $CopyWithPlaceholder()
          ? _value.takenAt
          // ignore: cast_nullable_to_non_nullable
          : takenAt as DateTime,
      lat: lat == const $CopyWithPlaceholder()
          ? _value.lat
          // ignore: cast_nullable_to_non_nullable
          : lat as num?,
      lng: lng == const $CopyWithPlaceholder()
          ? _value.lng
          // ignore: cast_nullable_to_non_nullable
          : lng as num?,
      accuracyM: accuracyM == const $CopyWithPlaceholder()
          ? _value.accuracyM
          // ignore: cast_nullable_to_non_nullable
          : accuracyM as num?,
    );
  }
}

extension $ProofPhotoCopyWith on ProofPhoto {
  /// Returns a callable class that can be used as follows: `instanceOfProofPhoto.copyWith(...)` or like so:`instanceOfProofPhoto.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ProofPhotoCWProxy get copyWith => _$ProofPhotoCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProofPhoto _$ProofPhotoFromJson(Map<String, dynamic> json) => $checkedCreate(
  'ProofPhoto',
  json,
  ($checkedConvert) {
    $checkKeys(json, requiredKeys: const ['url', 'taken_at']);
    final val = ProofPhoto(
      url: $checkedConvert('url', (v) => v as String),
      takenAt: $checkedConvert('taken_at', (v) => DateTime.parse(v as String)),
      lat: $checkedConvert('lat', (v) => v as num?),
      lng: $checkedConvert('lng', (v) => v as num?),
      accuracyM: $checkedConvert('accuracy_m', (v) => v as num?),
    );
    return val;
  },
  fieldKeyMap: const {'takenAt': 'taken_at', 'accuracyM': 'accuracy_m'},
);

Map<String, dynamic> _$ProofPhotoToJson(ProofPhoto instance) =>
    <String, dynamic>{
      'url': instance.url,
      'taken_at': instance.takenAt.toIso8601String(),
      'lat': ?instance.lat,
      'lng': ?instance.lng,
      'accuracy_m': ?instance.accuracyM,
    };
