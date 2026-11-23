// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lead_key_new.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$LeadKeyNewCWProxy {
  LeadKeyNew key(String key);

  LeadKeyNew madeAt(DateTime madeAt);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `LeadKeyNew(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// LeadKeyNew(...).copyWith(id: 12, name: "My name")
  /// ````
  LeadKeyNew call({String key, DateTime madeAt});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfLeadKeyNew.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfLeadKeyNew.copyWith.fieldName(...)`
class _$LeadKeyNewCWProxyImpl implements _$LeadKeyNewCWProxy {
  const _$LeadKeyNewCWProxyImpl(this._value);

  final LeadKeyNew _value;

  @override
  LeadKeyNew key(String key) => this(key: key);

  @override
  LeadKeyNew madeAt(DateTime madeAt) => this(madeAt: madeAt);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `LeadKeyNew(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// LeadKeyNew(...).copyWith(id: 12, name: "My name")
  /// ````
  LeadKeyNew call({
    Object? key = const $CopyWithPlaceholder(),
    Object? madeAt = const $CopyWithPlaceholder(),
  }) {
    return LeadKeyNew(
      key: key == const $CopyWithPlaceholder()
          ? _value.key
          // ignore: cast_nullable_to_non_nullable
          : key as String,
      madeAt: madeAt == const $CopyWithPlaceholder()
          ? _value.madeAt
          // ignore: cast_nullable_to_non_nullable
          : madeAt as DateTime,
    );
  }
}

extension $LeadKeyNewCopyWith on LeadKeyNew {
  /// Returns a callable class that can be used as follows: `instanceOfLeadKeyNew.copyWith(...)` or like so:`instanceOfLeadKeyNew.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$LeadKeyNewCWProxy get copyWith => _$LeadKeyNewCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LeadKeyNew _$LeadKeyNewFromJson(Map<String, dynamic> json) =>
    $checkedCreate('LeadKeyNew', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['key', 'made_at']);
      final val = LeadKeyNew(
        key: $checkedConvert('key', (v) => v as String),
        madeAt: $checkedConvert('made_at', (v) => DateTime.parse(v as String)),
      );
      return val;
    }, fieldKeyMap: const {'madeAt': 'made_at'});

Map<String, dynamic> _$LeadKeyNewToJson(LeadKeyNew instance) =>
    <String, dynamic>{
      'key': instance.key,
      'made_at': instance.madeAt.toIso8601String(),
    };
