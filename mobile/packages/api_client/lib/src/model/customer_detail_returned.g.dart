// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'customer_detail_returned.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$CustomerDetailReturnedCWProxy {
  CustomerDetailReturned kind(KycKind kind);

  CustomerDetailReturned title(String title);

  CustomerDetailReturned note(TaskNote note);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `CustomerDetailReturned(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// CustomerDetailReturned(...).copyWith(id: 12, name: "My name")
  /// ````
  CustomerDetailReturned call({KycKind kind, String title, TaskNote note});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfCustomerDetailReturned.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfCustomerDetailReturned.copyWith.fieldName(...)`
class _$CustomerDetailReturnedCWProxyImpl
    implements _$CustomerDetailReturnedCWProxy {
  const _$CustomerDetailReturnedCWProxyImpl(this._value);

  final CustomerDetailReturned _value;

  @override
  CustomerDetailReturned kind(KycKind kind) => this(kind: kind);

  @override
  CustomerDetailReturned title(String title) => this(title: title);

  @override
  CustomerDetailReturned note(TaskNote note) => this(note: note);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `CustomerDetailReturned(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// CustomerDetailReturned(...).copyWith(id: 12, name: "My name")
  /// ````
  CustomerDetailReturned call({
    Object? kind = const $CopyWithPlaceholder(),
    Object? title = const $CopyWithPlaceholder(),
    Object? note = const $CopyWithPlaceholder(),
  }) {
    return CustomerDetailReturned(
      kind: kind == const $CopyWithPlaceholder()
          ? _value.kind
          // ignore: cast_nullable_to_non_nullable
          : kind as KycKind,
      title: title == const $CopyWithPlaceholder()
          ? _value.title
          // ignore: cast_nullable_to_non_nullable
          : title as String,
      note: note == const $CopyWithPlaceholder()
          ? _value.note
          // ignore: cast_nullable_to_non_nullable
          : note as TaskNote,
    );
  }
}

extension $CustomerDetailReturnedCopyWith on CustomerDetailReturned {
  /// Returns a callable class that can be used as follows: `instanceOfCustomerDetailReturned.copyWith(...)` or like so:`instanceOfCustomerDetailReturned.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$CustomerDetailReturnedCWProxy get copyWith =>
      _$CustomerDetailReturnedCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CustomerDetailReturned _$CustomerDetailReturnedFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('CustomerDetailReturned', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['kind', 'title', 'note']);
  final val = CustomerDetailReturned(
    kind: $checkedConvert('kind', (v) => $enumDecode(_$KycKindEnumMap, v)),
    title: $checkedConvert('title', (v) => v as String),
    note: $checkedConvert(
      'note',
      (v) => TaskNote.fromJson(v as Map<String, dynamic>),
    ),
  );
  return val;
});

Map<String, dynamic> _$CustomerDetailReturnedToJson(
  CustomerDetailReturned instance,
) => <String, dynamic>{
  'kind': _$KycKindEnumMap[instance.kind]!,
  'title': instance.title,
  'note': instance.note.toJson(),
};

const _$KycKindEnumMap = {
  KycKind.aadhaar: 'aadhaar',
  KycKind.pan: 'pan',
  KycKind.electricityBill: 'electricity_bill',
  KycKind.bankProof: 'bank_proof',
  KycKind.roofPhoto: 'roof_photo',
};
