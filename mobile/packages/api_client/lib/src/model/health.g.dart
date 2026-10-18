// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'health.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$HealthCWProxy {
  Health status(HealthStatusEnum status);

  Health version(String version);

  Health database(HealthDatabaseEnum database);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `Health(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// Health(...).copyWith(id: 12, name: "My name")
  /// ````
  Health call({
    HealthStatusEnum status,
    String version,
    HealthDatabaseEnum database,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfHealth.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfHealth.copyWith.fieldName(...)`
class _$HealthCWProxyImpl implements _$HealthCWProxy {
  const _$HealthCWProxyImpl(this._value);

  final Health _value;

  @override
  Health status(HealthStatusEnum status) => this(status: status);

  @override
  Health version(String version) => this(version: version);

  @override
  Health database(HealthDatabaseEnum database) => this(database: database);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `Health(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// Health(...).copyWith(id: 12, name: "My name")
  /// ````
  Health call({
    Object? status = const $CopyWithPlaceholder(),
    Object? version = const $CopyWithPlaceholder(),
    Object? database = const $CopyWithPlaceholder(),
  }) {
    return Health(
      status: status == const $CopyWithPlaceholder()
          ? _value.status
          // ignore: cast_nullable_to_non_nullable
          : status as HealthStatusEnum,
      version: version == const $CopyWithPlaceholder()
          ? _value.version
          // ignore: cast_nullable_to_non_nullable
          : version as String,
      database: database == const $CopyWithPlaceholder()
          ? _value.database
          // ignore: cast_nullable_to_non_nullable
          : database as HealthDatabaseEnum,
    );
  }
}

extension $HealthCopyWith on Health {
  /// Returns a callable class that can be used as follows: `instanceOfHealth.copyWith(...)` or like so:`instanceOfHealth.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$HealthCWProxy get copyWith => _$HealthCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Health _$HealthFromJson(Map<String, dynamic> json) =>
    $checkedCreate('Health', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['status', 'version', 'database']);
      final val = Health(
        status: $checkedConvert(
          'status',
          (v) => $enumDecode(_$HealthStatusEnumEnumMap, v),
        ),
        version: $checkedConvert('version', (v) => v as String),
        database: $checkedConvert(
          'database',
          (v) => $enumDecode(_$HealthDatabaseEnumEnumMap, v),
        ),
      );
      return val;
    });

Map<String, dynamic> _$HealthToJson(Health instance) => <String, dynamic>{
  'status': _$HealthStatusEnumEnumMap[instance.status]!,
  'version': instance.version,
  'database': _$HealthDatabaseEnumEnumMap[instance.database]!,
};

const _$HealthStatusEnumEnumMap = {
  HealthStatusEnum.ok: 'ok',
  HealthStatusEnum.degraded: 'degraded',
};

const _$HealthDatabaseEnumEnumMap = {
  HealthDatabaseEnum.ok: 'ok',
  HealthDatabaseEnum.unavailable: 'unavailable',
};
