// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lead_key_info.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$LeadKeyInfoCWProxy {
  LeadKeyInfo set_(bool set_);

  LeadKeyInfo madeAt(DateTime? madeAt);

  LeadKeyInfo lastUsedAt(DateTime? lastUsedAt);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `LeadKeyInfo(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// LeadKeyInfo(...).copyWith(id: 12, name: "My name")
  /// ````
  LeadKeyInfo call({bool set_, DateTime? madeAt, DateTime? lastUsedAt});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfLeadKeyInfo.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfLeadKeyInfo.copyWith.fieldName(...)`
class _$LeadKeyInfoCWProxyImpl implements _$LeadKeyInfoCWProxy {
  const _$LeadKeyInfoCWProxyImpl(this._value);

  final LeadKeyInfo _value;

  @override
  LeadKeyInfo set_(bool set_) => this(set_: set_);

  @override
  LeadKeyInfo madeAt(DateTime? madeAt) => this(madeAt: madeAt);

  @override
  LeadKeyInfo lastUsedAt(DateTime? lastUsedAt) => this(lastUsedAt: lastUsedAt);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `LeadKeyInfo(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// LeadKeyInfo(...).copyWith(id: 12, name: "My name")
  /// ````
  LeadKeyInfo call({
    Object? set_ = const $CopyWithPlaceholder(),
    Object? madeAt = const $CopyWithPlaceholder(),
    Object? lastUsedAt = const $CopyWithPlaceholder(),
  }) {
    return LeadKeyInfo(
      set_: set_ == const $CopyWithPlaceholder()
          ? _value.set_
          // ignore: cast_nullable_to_non_nullable
          : set_ as bool,
      madeAt: madeAt == const $CopyWithPlaceholder()
          ? _value.madeAt
          // ignore: cast_nullable_to_non_nullable
          : madeAt as DateTime?,
      lastUsedAt: lastUsedAt == const $CopyWithPlaceholder()
          ? _value.lastUsedAt
          // ignore: cast_nullable_to_non_nullable
          : lastUsedAt as DateTime?,
    );
  }
}

extension $LeadKeyInfoCopyWith on LeadKeyInfo {
  /// Returns a callable class that can be used as follows: `instanceOfLeadKeyInfo.copyWith(...)` or like so:`instanceOfLeadKeyInfo.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$LeadKeyInfoCWProxy get copyWith => _$LeadKeyInfoCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LeadKeyInfo _$LeadKeyInfoFromJson(Map<String, dynamic> json) => $checkedCreate(
  'LeadKeyInfo',
  json,
  ($checkedConvert) {
    $checkKeys(json, requiredKeys: const ['set']);
    final val = LeadKeyInfo(
      set_: $checkedConvert('set', (v) => v as bool),
      madeAt: $checkedConvert(
        'made_at',
        (v) => v == null ? null : DateTime.parse(v as String),
      ),
      lastUsedAt: $checkedConvert(
        'last_used_at',
        (v) => v == null ? null : DateTime.parse(v as String),
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'set_': 'set',
    'madeAt': 'made_at',
    'lastUsedAt': 'last_used_at',
  },
);

Map<String, dynamic> _$LeadKeyInfoToJson(LeadKeyInfo instance) =>
    <String, dynamic>{
      'set': instance.set_,
      'made_at': ?instance.madeAt?.toIso8601String(),
      'last_used_at': ?instance.lastUsedAt?.toIso8601String(),
    };
