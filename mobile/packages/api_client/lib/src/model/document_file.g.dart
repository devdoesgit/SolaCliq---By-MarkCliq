// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'document_file.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$DocumentFileCWProxy {
  DocumentFile uploadId(String uploadId);

  DocumentFile side(DocumentSide? side);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `DocumentFile(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// DocumentFile(...).copyWith(id: 12, name: "My name")
  /// ````
  DocumentFile call({String uploadId, DocumentSide? side});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfDocumentFile.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfDocumentFile.copyWith.fieldName(...)`
class _$DocumentFileCWProxyImpl implements _$DocumentFileCWProxy {
  const _$DocumentFileCWProxyImpl(this._value);

  final DocumentFile _value;

  @override
  DocumentFile uploadId(String uploadId) => this(uploadId: uploadId);

  @override
  DocumentFile side(DocumentSide? side) => this(side: side);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `DocumentFile(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// DocumentFile(...).copyWith(id: 12, name: "My name")
  /// ````
  DocumentFile call({
    Object? uploadId = const $CopyWithPlaceholder(),
    Object? side = const $CopyWithPlaceholder(),
  }) {
    return DocumentFile(
      uploadId: uploadId == const $CopyWithPlaceholder()
          ? _value.uploadId
          // ignore: cast_nullable_to_non_nullable
          : uploadId as String,
      side: side == const $CopyWithPlaceholder()
          ? _value.side
          // ignore: cast_nullable_to_non_nullable
          : side as DocumentSide?,
    );
  }
}

extension $DocumentFileCopyWith on DocumentFile {
  /// Returns a callable class that can be used as follows: `instanceOfDocumentFile.copyWith(...)` or like so:`instanceOfDocumentFile.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$DocumentFileCWProxy get copyWith => _$DocumentFileCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DocumentFile _$DocumentFileFromJson(Map<String, dynamic> json) =>
    $checkedCreate('DocumentFile', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['upload_id']);
      final val = DocumentFile(
        uploadId: $checkedConvert('upload_id', (v) => v as String),
        side: $checkedConvert(
          'side',
          (v) => $enumDecodeNullable(_$DocumentSideEnumMap, v),
        ),
      );
      return val;
    }, fieldKeyMap: const {'uploadId': 'upload_id'});

Map<String, dynamic> _$DocumentFileToJson(DocumentFile instance) =>
    <String, dynamic>{
      'upload_id': instance.uploadId,
      'side': ?_$DocumentSideEnumMap[instance.side],
    };

const _$DocumentSideEnumMap = {
  DocumentSide.front: 'front',
  DocumentSide.back: 'back',
};
