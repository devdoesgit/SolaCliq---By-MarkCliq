// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_document_file.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$AdminDocumentFileCWProxy {
  AdminDocumentFile file(AdminFile file);

  AdminDocumentFile side(DocumentSide? side);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `AdminDocumentFile(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// AdminDocumentFile(...).copyWith(id: 12, name: "My name")
  /// ````
  AdminDocumentFile call({AdminFile file, DocumentSide? side});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfAdminDocumentFile.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfAdminDocumentFile.copyWith.fieldName(...)`
class _$AdminDocumentFileCWProxyImpl implements _$AdminDocumentFileCWProxy {
  const _$AdminDocumentFileCWProxyImpl(this._value);

  final AdminDocumentFile _value;

  @override
  AdminDocumentFile file(AdminFile file) => this(file: file);

  @override
  AdminDocumentFile side(DocumentSide? side) => this(side: side);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `AdminDocumentFile(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// AdminDocumentFile(...).copyWith(id: 12, name: "My name")
  /// ````
  AdminDocumentFile call({
    Object? file = const $CopyWithPlaceholder(),
    Object? side = const $CopyWithPlaceholder(),
  }) {
    return AdminDocumentFile(
      file: file == const $CopyWithPlaceholder()
          ? _value.file
          // ignore: cast_nullable_to_non_nullable
          : file as AdminFile,
      side: side == const $CopyWithPlaceholder()
          ? _value.side
          // ignore: cast_nullable_to_non_nullable
          : side as DocumentSide?,
    );
  }
}

extension $AdminDocumentFileCopyWith on AdminDocumentFile {
  /// Returns a callable class that can be used as follows: `instanceOfAdminDocumentFile.copyWith(...)` or like so:`instanceOfAdminDocumentFile.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$AdminDocumentFileCWProxy get copyWith =>
      _$AdminDocumentFileCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AdminDocumentFile _$AdminDocumentFileFromJson(Map<String, dynamic> json) =>
    $checkedCreate('AdminDocumentFile', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['file']);
      final val = AdminDocumentFile(
        file: $checkedConvert(
          'file',
          (v) => AdminFile.fromJson(v as Map<String, dynamic>),
        ),
        side: $checkedConvert(
          'side',
          (v) => $enumDecodeNullable(_$DocumentSideEnumMap, v),
        ),
      );
      return val;
    });

Map<String, dynamic> _$AdminDocumentFileToJson(AdminDocumentFile instance) =>
    <String, dynamic>{
      'file': instance.file.toJson(),
      'side': ?_$DocumentSideEnumMap[instance.side],
    };

const _$DocumentSideEnumMap = {
  DocumentSide.front: 'front',
  DocumentSide.back: 'back',
};
