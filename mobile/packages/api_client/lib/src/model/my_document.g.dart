// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'my_document.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$MyDocumentCWProxy {
  MyDocument kind(KycKind kind);

  MyDocument detail(String? detail);

  MyDocument status(DocumentStatus status);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `MyDocument(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// MyDocument(...).copyWith(id: 12, name: "My name")
  /// ````
  MyDocument call({KycKind kind, String? detail, DocumentStatus status});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfMyDocument.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfMyDocument.copyWith.fieldName(...)`
class _$MyDocumentCWProxyImpl implements _$MyDocumentCWProxy {
  const _$MyDocumentCWProxyImpl(this._value);

  final MyDocument _value;

  @override
  MyDocument kind(KycKind kind) => this(kind: kind);

  @override
  MyDocument detail(String? detail) => this(detail: detail);

  @override
  MyDocument status(DocumentStatus status) => this(status: status);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `MyDocument(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// MyDocument(...).copyWith(id: 12, name: "My name")
  /// ````
  MyDocument call({
    Object? kind = const $CopyWithPlaceholder(),
    Object? detail = const $CopyWithPlaceholder(),
    Object? status = const $CopyWithPlaceholder(),
  }) {
    return MyDocument(
      kind: kind == const $CopyWithPlaceholder()
          ? _value.kind
          // ignore: cast_nullable_to_non_nullable
          : kind as KycKind,
      detail: detail == const $CopyWithPlaceholder()
          ? _value.detail
          // ignore: cast_nullable_to_non_nullable
          : detail as String?,
      status: status == const $CopyWithPlaceholder()
          ? _value.status
          // ignore: cast_nullable_to_non_nullable
          : status as DocumentStatus,
    );
  }
}

extension $MyDocumentCopyWith on MyDocument {
  /// Returns a callable class that can be used as follows: `instanceOfMyDocument.copyWith(...)` or like so:`instanceOfMyDocument.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$MyDocumentCWProxy get copyWith => _$MyDocumentCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MyDocument _$MyDocumentFromJson(Map<String, dynamic> json) =>
    $checkedCreate('MyDocument', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['kind', 'status']);
      final val = MyDocument(
        kind: $checkedConvert('kind', (v) => $enumDecode(_$KycKindEnumMap, v)),
        detail: $checkedConvert('detail', (v) => v as String?),
        status: $checkedConvert(
          'status',
          (v) => $enumDecode(_$DocumentStatusEnumMap, v),
        ),
      );
      return val;
    });

Map<String, dynamic> _$MyDocumentToJson(MyDocument instance) =>
    <String, dynamic>{
      'kind': _$KycKindEnumMap[instance.kind]!,
      'detail': ?instance.detail,
      'status': _$DocumentStatusEnumMap[instance.status]!,
    };

const _$KycKindEnumMap = {
  KycKind.aadhaar: 'aadhaar',
  KycKind.pan: 'pan',
  KycKind.electricityBill: 'electricity_bill',
  KycKind.bankProof: 'bank_proof',
  KycKind.roofPhoto: 'roof_photo',
};

const _$DocumentStatusEnumMap = {
  DocumentStatus.verified: 'verified',
  DocumentStatus.inReview: 'in_review',
  DocumentStatus.needsFix: 'needs_fix',
};
