// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lead_receipt.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$LeadReceiptCWProxy {
  LeadReceipt id(String id);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `LeadReceipt(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// LeadReceipt(...).copyWith(id: 12, name: "My name")
  /// ````
  LeadReceipt call({String id});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfLeadReceipt.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfLeadReceipt.copyWith.fieldName(...)`
class _$LeadReceiptCWProxyImpl implements _$LeadReceiptCWProxy {
  const _$LeadReceiptCWProxyImpl(this._value);

  final LeadReceipt _value;

  @override
  LeadReceipt id(String id) => this(id: id);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `LeadReceipt(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// LeadReceipt(...).copyWith(id: 12, name: "My name")
  /// ````
  LeadReceipt call({Object? id = const $CopyWithPlaceholder()}) {
    return LeadReceipt(
      id: id == const $CopyWithPlaceholder()
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
    );
  }
}

extension $LeadReceiptCopyWith on LeadReceipt {
  /// Returns a callable class that can be used as follows: `instanceOfLeadReceipt.copyWith(...)` or like so:`instanceOfLeadReceipt.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$LeadReceiptCWProxy get copyWith => _$LeadReceiptCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LeadReceipt _$LeadReceiptFromJson(Map<String, dynamic> json) =>
    $checkedCreate('LeadReceipt', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['id']);
      final val = LeadReceipt(id: $checkedConvert('id', (v) => v as String));
      return val;
    });

Map<String, dynamic> _$LeadReceiptToJson(LeadReceipt instance) =>
    <String, dynamic>{'id': instance.id};
