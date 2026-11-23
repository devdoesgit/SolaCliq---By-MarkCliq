// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'document_replace.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$DocumentReplaceCWProxy {
  DocumentReplace files(List<DocumentFile> files);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `DocumentReplace(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// DocumentReplace(...).copyWith(id: 12, name: "My name")
  /// ````
  DocumentReplace call({List<DocumentFile> files});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfDocumentReplace.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfDocumentReplace.copyWith.fieldName(...)`
class _$DocumentReplaceCWProxyImpl implements _$DocumentReplaceCWProxy {
  const _$DocumentReplaceCWProxyImpl(this._value);

  final DocumentReplace _value;

  @override
  DocumentReplace files(List<DocumentFile> files) => this(files: files);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `DocumentReplace(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// DocumentReplace(...).copyWith(id: 12, name: "My name")
  /// ````
  DocumentReplace call({Object? files = const $CopyWithPlaceholder()}) {
    return DocumentReplace(
      files: files == const $CopyWithPlaceholder()
          ? _value.files
          // ignore: cast_nullable_to_non_nullable
          : files as List<DocumentFile>,
    );
  }
}

extension $DocumentReplaceCopyWith on DocumentReplace {
  /// Returns a callable class that can be used as follows: `instanceOfDocumentReplace.copyWith(...)` or like so:`instanceOfDocumentReplace.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$DocumentReplaceCWProxy get copyWith => _$DocumentReplaceCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DocumentReplace _$DocumentReplaceFromJson(Map<String, dynamic> json) =>
    $checkedCreate('DocumentReplace', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['files']);
      final val = DocumentReplace(
        files: $checkedConvert(
          'files',
          (v) => (v as List<dynamic>)
              .map((e) => DocumentFile.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$DocumentReplaceToJson(DocumentReplace instance) =>
    <String, dynamic>{'files': instance.files.map((e) => e.toJson()).toList()};
