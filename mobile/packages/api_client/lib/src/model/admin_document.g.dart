// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_document.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$AdminDocumentCWProxy {
  AdminDocument kind(KycKind kind);

  AdminDocument title(String title);

  AdminDocument status(DocumentStatus status);

  AdminDocument files(List<AdminDocumentFile> files);

  AdminDocument note(String? note);

  AdminDocument updatedAt(DateTime updatedAt);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `AdminDocument(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// AdminDocument(...).copyWith(id: 12, name: "My name")
  /// ````
  AdminDocument call({
    KycKind kind,
    String title,
    DocumentStatus status,
    List<AdminDocumentFile> files,
    String? note,
    DateTime updatedAt,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfAdminDocument.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfAdminDocument.copyWith.fieldName(...)`
class _$AdminDocumentCWProxyImpl implements _$AdminDocumentCWProxy {
  const _$AdminDocumentCWProxyImpl(this._value);

  final AdminDocument _value;

  @override
  AdminDocument kind(KycKind kind) => this(kind: kind);

  @override
  AdminDocument title(String title) => this(title: title);

  @override
  AdminDocument status(DocumentStatus status) => this(status: status);

  @override
  AdminDocument files(List<AdminDocumentFile> files) => this(files: files);

  @override
  AdminDocument note(String? note) => this(note: note);

  @override
  AdminDocument updatedAt(DateTime updatedAt) => this(updatedAt: updatedAt);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `AdminDocument(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// AdminDocument(...).copyWith(id: 12, name: "My name")
  /// ````
  AdminDocument call({
    Object? kind = const $CopyWithPlaceholder(),
    Object? title = const $CopyWithPlaceholder(),
    Object? status = const $CopyWithPlaceholder(),
    Object? files = const $CopyWithPlaceholder(),
    Object? note = const $CopyWithPlaceholder(),
    Object? updatedAt = const $CopyWithPlaceholder(),
  }) {
    return AdminDocument(
      kind: kind == const $CopyWithPlaceholder()
          ? _value.kind
          // ignore: cast_nullable_to_non_nullable
          : kind as KycKind,
      title: title == const $CopyWithPlaceholder()
          ? _value.title
          // ignore: cast_nullable_to_non_nullable
          : title as String,
      status: status == const $CopyWithPlaceholder()
          ? _value.status
          // ignore: cast_nullable_to_non_nullable
          : status as DocumentStatus,
      files: files == const $CopyWithPlaceholder()
          ? _value.files
          // ignore: cast_nullable_to_non_nullable
          : files as List<AdminDocumentFile>,
      note: note == const $CopyWithPlaceholder()
          ? _value.note
          // ignore: cast_nullable_to_non_nullable
          : note as String?,
      updatedAt: updatedAt == const $CopyWithPlaceholder()
          ? _value.updatedAt
          // ignore: cast_nullable_to_non_nullable
          : updatedAt as DateTime,
    );
  }
}

extension $AdminDocumentCopyWith on AdminDocument {
  /// Returns a callable class that can be used as follows: `instanceOfAdminDocument.copyWith(...)` or like so:`instanceOfAdminDocument.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$AdminDocumentCWProxy get copyWith => _$AdminDocumentCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AdminDocument _$AdminDocumentFromJson(Map<String, dynamic> json) =>
    $checkedCreate('AdminDocument', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const ['kind', 'title', 'status', 'files', 'updated_at'],
      );
      final val = AdminDocument(
        kind: $checkedConvert('kind', (v) => $enumDecode(_$KycKindEnumMap, v)),
        title: $checkedConvert('title', (v) => v as String),
        status: $checkedConvert(
          'status',
          (v) => $enumDecode(_$DocumentStatusEnumMap, v),
        ),
        files: $checkedConvert(
          'files',
          (v) => (v as List<dynamic>)
              .map((e) => AdminDocumentFile.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
        note: $checkedConvert('note', (v) => v as String?),
        updatedAt: $checkedConvert(
          'updated_at',
          (v) => DateTime.parse(v as String),
        ),
      );
      return val;
    }, fieldKeyMap: const {'updatedAt': 'updated_at'});

Map<String, dynamic> _$AdminDocumentToJson(AdminDocument instance) =>
    <String, dynamic>{
      'kind': _$KycKindEnumMap[instance.kind]!,
      'title': instance.title,
      'status': _$DocumentStatusEnumMap[instance.status]!,
      'files': instance.files.map((e) => e.toJson()).toList(),
      'note': ?instance.note,
      'updated_at': instance.updatedAt.toIso8601String(),
    };

const _$KycKindEnumMap = {
  KycKind.aadhaar: 'aadhaar',
  KycKind.pan: 'pan',
  KycKind.electricityBill: 'electricity_bill',
  KycKind.bankProof: 'bank_proof',
  KycKind.roofPhoto: 'roof_photo',
  KycKind.landDocument: 'land_document',
  KycKind.signature: 'signature',
  KycKind.nameChange: 'name_change',
};

const _$DocumentStatusEnumMap = {
  DocumentStatus.verified: 'verified',
  DocumentStatus.inReview: 'in_review',
  DocumentStatus.needsFix: 'needs_fix',
};
