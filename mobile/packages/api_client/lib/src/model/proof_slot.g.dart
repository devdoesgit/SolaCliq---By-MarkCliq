// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'proof_slot.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ProofSlotCWProxy {
  ProofSlot id(String id);

  ProofSlot label(String label);

  ProofSlot hint(String? hint);

  ProofSlot photo(ProofPhoto? photo);

  ProofSlot retake(bool? retake);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ProofSlot(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ProofSlot(...).copyWith(id: 12, name: "My name")
  /// ````
  ProofSlot call({
    String id,
    String label,
    String? hint,
    ProofPhoto? photo,
    bool? retake,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfProofSlot.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfProofSlot.copyWith.fieldName(...)`
class _$ProofSlotCWProxyImpl implements _$ProofSlotCWProxy {
  const _$ProofSlotCWProxyImpl(this._value);

  final ProofSlot _value;

  @override
  ProofSlot id(String id) => this(id: id);

  @override
  ProofSlot label(String label) => this(label: label);

  @override
  ProofSlot hint(String? hint) => this(hint: hint);

  @override
  ProofSlot photo(ProofPhoto? photo) => this(photo: photo);

  @override
  ProofSlot retake(bool? retake) => this(retake: retake);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ProofSlot(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ProofSlot(...).copyWith(id: 12, name: "My name")
  /// ````
  ProofSlot call({
    Object? id = const $CopyWithPlaceholder(),
    Object? label = const $CopyWithPlaceholder(),
    Object? hint = const $CopyWithPlaceholder(),
    Object? photo = const $CopyWithPlaceholder(),
    Object? retake = const $CopyWithPlaceholder(),
  }) {
    return ProofSlot(
      id: id == const $CopyWithPlaceholder()
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      label: label == const $CopyWithPlaceholder()
          ? _value.label
          // ignore: cast_nullable_to_non_nullable
          : label as String,
      hint: hint == const $CopyWithPlaceholder()
          ? _value.hint
          // ignore: cast_nullable_to_non_nullable
          : hint as String?,
      photo: photo == const $CopyWithPlaceholder()
          ? _value.photo
          // ignore: cast_nullable_to_non_nullable
          : photo as ProofPhoto?,
      retake: retake == const $CopyWithPlaceholder()
          ? _value.retake
          // ignore: cast_nullable_to_non_nullable
          : retake as bool?,
    );
  }
}

extension $ProofSlotCopyWith on ProofSlot {
  /// Returns a callable class that can be used as follows: `instanceOfProofSlot.copyWith(...)` or like so:`instanceOfProofSlot.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ProofSlotCWProxy get copyWith => _$ProofSlotCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProofSlot _$ProofSlotFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ProofSlot', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['id', 'label']);
      final val = ProofSlot(
        id: $checkedConvert('id', (v) => v as String),
        label: $checkedConvert('label', (v) => v as String),
        hint: $checkedConvert('hint', (v) => v as String?),
        photo: $checkedConvert(
          'photo',
          (v) =>
              v == null ? null : ProofPhoto.fromJson(v as Map<String, dynamic>),
        ),
        retake: $checkedConvert('retake', (v) => v as bool? ?? false),
      );
      return val;
    });

Map<String, dynamic> _$ProofSlotToJson(ProofSlot instance) => <String, dynamic>{
  'id': instance.id,
  'label': instance.label,
  'hint': ?instance.hint,
  'photo': ?instance.photo?.toJson(),
  'retake': ?instance.retake,
};
