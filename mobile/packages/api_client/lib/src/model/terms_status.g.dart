// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'terms_status.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$TermsStatusCWProxy {
  TermsStatus acceptedVersion(int? acceptedVersion);

  TermsStatus currentVersion(int currentVersion);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `TermsStatus(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// TermsStatus(...).copyWith(id: 12, name: "My name")
  /// ````
  TermsStatus call({int? acceptedVersion, int currentVersion});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfTermsStatus.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfTermsStatus.copyWith.fieldName(...)`
class _$TermsStatusCWProxyImpl implements _$TermsStatusCWProxy {
  const _$TermsStatusCWProxyImpl(this._value);

  final TermsStatus _value;

  @override
  TermsStatus acceptedVersion(int? acceptedVersion) =>
      this(acceptedVersion: acceptedVersion);

  @override
  TermsStatus currentVersion(int currentVersion) =>
      this(currentVersion: currentVersion);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `TermsStatus(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// TermsStatus(...).copyWith(id: 12, name: "My name")
  /// ````
  TermsStatus call({
    Object? acceptedVersion = const $CopyWithPlaceholder(),
    Object? currentVersion = const $CopyWithPlaceholder(),
  }) {
    return TermsStatus(
      acceptedVersion: acceptedVersion == const $CopyWithPlaceholder()
          ? _value.acceptedVersion
          // ignore: cast_nullable_to_non_nullable
          : acceptedVersion as int?,
      currentVersion: currentVersion == const $CopyWithPlaceholder()
          ? _value.currentVersion
          // ignore: cast_nullable_to_non_nullable
          : currentVersion as int,
    );
  }
}

extension $TermsStatusCopyWith on TermsStatus {
  /// Returns a callable class that can be used as follows: `instanceOfTermsStatus.copyWith(...)` or like so:`instanceOfTermsStatus.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$TermsStatusCWProxy get copyWith => _$TermsStatusCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TermsStatus _$TermsStatusFromJson(Map<String, dynamic> json) => $checkedCreate(
  'TermsStatus',
  json,
  ($checkedConvert) {
    $checkKeys(json, requiredKeys: const ['current_version']);
    final val = TermsStatus(
      acceptedVersion: $checkedConvert(
        'accepted_version',
        (v) => (v as num?)?.toInt(),
      ),
      currentVersion: $checkedConvert(
        'current_version',
        (v) => (v as num).toInt(),
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'acceptedVersion': 'accepted_version',
    'currentVersion': 'current_version',
  },
);

Map<String, dynamic> _$TermsStatusToJson(TermsStatus instance) =>
    <String, dynamic>{
      'accepted_version': ?instance.acceptedVersion,
      'current_version': instance.currentVersion,
    };
