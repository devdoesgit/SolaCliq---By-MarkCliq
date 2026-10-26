// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'proof_photo_create.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ProofPhotoCreateCWProxy {
  ProofPhotoCreate slotId(String slotId);

  ProofPhotoCreate uploadId(String uploadId);

  ProofPhotoCreate takenAt(DateTime takenAt);

  ProofPhotoCreate lat(num lat);

  ProofPhotoCreate lng(num lng);

  ProofPhotoCreate accuracyM(num accuracyM);

  ProofPhotoCreate mockedLocation(bool? mockedLocation);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ProofPhotoCreate(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ProofPhotoCreate(...).copyWith(id: 12, name: "My name")
  /// ````
  ProofPhotoCreate call({
    String slotId,
    String uploadId,
    DateTime takenAt,
    num lat,
    num lng,
    num accuracyM,
    bool? mockedLocation,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfProofPhotoCreate.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfProofPhotoCreate.copyWith.fieldName(...)`
class _$ProofPhotoCreateCWProxyImpl implements _$ProofPhotoCreateCWProxy {
  const _$ProofPhotoCreateCWProxyImpl(this._value);

  final ProofPhotoCreate _value;

  @override
  ProofPhotoCreate slotId(String slotId) => this(slotId: slotId);

  @override
  ProofPhotoCreate uploadId(String uploadId) => this(uploadId: uploadId);

  @override
  ProofPhotoCreate takenAt(DateTime takenAt) => this(takenAt: takenAt);

  @override
  ProofPhotoCreate lat(num lat) => this(lat: lat);

  @override
  ProofPhotoCreate lng(num lng) => this(lng: lng);

  @override
  ProofPhotoCreate accuracyM(num accuracyM) => this(accuracyM: accuracyM);

  @override
  ProofPhotoCreate mockedLocation(bool? mockedLocation) =>
      this(mockedLocation: mockedLocation);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ProofPhotoCreate(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ProofPhotoCreate(...).copyWith(id: 12, name: "My name")
  /// ````
  ProofPhotoCreate call({
    Object? slotId = const $CopyWithPlaceholder(),
    Object? uploadId = const $CopyWithPlaceholder(),
    Object? takenAt = const $CopyWithPlaceholder(),
    Object? lat = const $CopyWithPlaceholder(),
    Object? lng = const $CopyWithPlaceholder(),
    Object? accuracyM = const $CopyWithPlaceholder(),
    Object? mockedLocation = const $CopyWithPlaceholder(),
  }) {
    return ProofPhotoCreate(
      slotId: slotId == const $CopyWithPlaceholder()
          ? _value.slotId
          // ignore: cast_nullable_to_non_nullable
          : slotId as String,
      uploadId: uploadId == const $CopyWithPlaceholder()
          ? _value.uploadId
          // ignore: cast_nullable_to_non_nullable
          : uploadId as String,
      takenAt: takenAt == const $CopyWithPlaceholder()
          ? _value.takenAt
          // ignore: cast_nullable_to_non_nullable
          : takenAt as DateTime,
      lat: lat == const $CopyWithPlaceholder()
          ? _value.lat
          // ignore: cast_nullable_to_non_nullable
          : lat as num,
      lng: lng == const $CopyWithPlaceholder()
          ? _value.lng
          // ignore: cast_nullable_to_non_nullable
          : lng as num,
      accuracyM: accuracyM == const $CopyWithPlaceholder()
          ? _value.accuracyM
          // ignore: cast_nullable_to_non_nullable
          : accuracyM as num,
      mockedLocation: mockedLocation == const $CopyWithPlaceholder()
          ? _value.mockedLocation
          // ignore: cast_nullable_to_non_nullable
          : mockedLocation as bool?,
    );
  }
}

extension $ProofPhotoCreateCopyWith on ProofPhotoCreate {
  /// Returns a callable class that can be used as follows: `instanceOfProofPhotoCreate.copyWith(...)` or like so:`instanceOfProofPhotoCreate.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ProofPhotoCreateCWProxy get copyWith => _$ProofPhotoCreateCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProofPhotoCreate _$ProofPhotoCreateFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'ProofPhotoCreate',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'slot_id',
            'upload_id',
            'taken_at',
            'lat',
            'lng',
            'accuracy_m',
          ],
        );
        final val = ProofPhotoCreate(
          slotId: $checkedConvert('slot_id', (v) => v as String),
          uploadId: $checkedConvert('upload_id', (v) => v as String),
          takenAt: $checkedConvert(
            'taken_at',
            (v) => DateTime.parse(v as String),
          ),
          lat: $checkedConvert('lat', (v) => v as num),
          lng: $checkedConvert('lng', (v) => v as num),
          accuracyM: $checkedConvert('accuracy_m', (v) => v as num),
          mockedLocation: $checkedConvert(
            'mocked_location',
            (v) => v as bool? ?? false,
          ),
        );
        return val;
      },
      fieldKeyMap: const {
        'slotId': 'slot_id',
        'uploadId': 'upload_id',
        'takenAt': 'taken_at',
        'accuracyM': 'accuracy_m',
        'mockedLocation': 'mocked_location',
      },
    );

Map<String, dynamic> _$ProofPhotoCreateToJson(ProofPhotoCreate instance) =>
    <String, dynamic>{
      'slot_id': instance.slotId,
      'upload_id': instance.uploadId,
      'taken_at': instance.takenAt.toIso8601String(),
      'lat': instance.lat,
      'lng': instance.lng,
      'accuracy_m': instance.accuracyM,
      'mocked_location': ?instance.mockedLocation,
    };
