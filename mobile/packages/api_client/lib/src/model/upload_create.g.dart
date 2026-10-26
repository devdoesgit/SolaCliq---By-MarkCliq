// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'upload_create.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$UploadCreateCWProxy {
  UploadCreate contentType(UploadCreateContentTypeEnum contentType);

  UploadCreate sizeBytes(int sizeBytes);

  UploadCreate purpose(UploadCreatePurposeEnum purpose);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `UploadCreate(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// UploadCreate(...).copyWith(id: 12, name: "My name")
  /// ````
  UploadCreate call({
    UploadCreateContentTypeEnum contentType,
    int sizeBytes,
    UploadCreatePurposeEnum purpose,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfUploadCreate.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfUploadCreate.copyWith.fieldName(...)`
class _$UploadCreateCWProxyImpl implements _$UploadCreateCWProxy {
  const _$UploadCreateCWProxyImpl(this._value);

  final UploadCreate _value;

  @override
  UploadCreate contentType(UploadCreateContentTypeEnum contentType) =>
      this(contentType: contentType);

  @override
  UploadCreate sizeBytes(int sizeBytes) => this(sizeBytes: sizeBytes);

  @override
  UploadCreate purpose(UploadCreatePurposeEnum purpose) =>
      this(purpose: purpose);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `UploadCreate(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// UploadCreate(...).copyWith(id: 12, name: "My name")
  /// ````
  UploadCreate call({
    Object? contentType = const $CopyWithPlaceholder(),
    Object? sizeBytes = const $CopyWithPlaceholder(),
    Object? purpose = const $CopyWithPlaceholder(),
  }) {
    return UploadCreate(
      contentType: contentType == const $CopyWithPlaceholder()
          ? _value.contentType
          // ignore: cast_nullable_to_non_nullable
          : contentType as UploadCreateContentTypeEnum,
      sizeBytes: sizeBytes == const $CopyWithPlaceholder()
          ? _value.sizeBytes
          // ignore: cast_nullable_to_non_nullable
          : sizeBytes as int,
      purpose: purpose == const $CopyWithPlaceholder()
          ? _value.purpose
          // ignore: cast_nullable_to_non_nullable
          : purpose as UploadCreatePurposeEnum,
    );
  }
}

extension $UploadCreateCopyWith on UploadCreate {
  /// Returns a callable class that can be used as follows: `instanceOfUploadCreate.copyWith(...)` or like so:`instanceOfUploadCreate.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$UploadCreateCWProxy get copyWith => _$UploadCreateCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UploadCreate _$UploadCreateFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'UploadCreate',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['content_type', 'size_bytes', 'purpose'],
        );
        final val = UploadCreate(
          contentType: $checkedConvert(
            'content_type',
            (v) => $enumDecode(_$UploadCreateContentTypeEnumEnumMap, v),
          ),
          sizeBytes: $checkedConvert('size_bytes', (v) => (v as num).toInt()),
          purpose: $checkedConvert(
            'purpose',
            (v) => $enumDecode(_$UploadCreatePurposeEnumEnumMap, v),
          ),
        );
        return val;
      },
      fieldKeyMap: const {
        'contentType': 'content_type',
        'sizeBytes': 'size_bytes',
      },
    );

Map<String, dynamic> _$UploadCreateToJson(
  UploadCreate instance,
) => <String, dynamic>{
  'content_type': _$UploadCreateContentTypeEnumEnumMap[instance.contentType]!,
  'size_bytes': instance.sizeBytes,
  'purpose': _$UploadCreatePurposeEnumEnumMap[instance.purpose]!,
};

const _$UploadCreateContentTypeEnumEnumMap = {
  UploadCreateContentTypeEnum.imageSlashJpeg: 'image/jpeg',
  UploadCreateContentTypeEnum.imageSlashPng: 'image/png',
  UploadCreateContentTypeEnum.applicationSlashPdf: 'application/pdf',
};

const _$UploadCreatePurposeEnumEnumMap = {
  UploadCreatePurposeEnum.receipt: 'receipt',
  UploadCreatePurposeEnum.kyc: 'kyc',
  UploadCreatePurposeEnum.proof: 'proof',
};
