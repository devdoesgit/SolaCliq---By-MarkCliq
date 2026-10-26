// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'install.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$InstallCWProxy {
  Install systemKw(num systemKw);

  Install place(String place);

  Install stageIndex(int stageIndex);

  Install stageCount(int stageCount);

  Install total(int total);

  Install subsidy(int subsidy);

  Install handedOverOn(String? handedOverOn);

  Install upiUri(String? upiUri);

  Install nextVisit(InstallNextVisit? nextVisit);

  Install stages(List<InstallStage> stages);

  Install payments(List<InstallPayment> payments);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `Install(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// Install(...).copyWith(id: 12, name: "My name")
  /// ````
  Install call({
    num systemKw,
    String place,
    int stageIndex,
    int stageCount,
    int total,
    int subsidy,
    String? handedOverOn,
    String? upiUri,
    InstallNextVisit? nextVisit,
    List<InstallStage> stages,
    List<InstallPayment> payments,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfInstall.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfInstall.copyWith.fieldName(...)`
class _$InstallCWProxyImpl implements _$InstallCWProxy {
  const _$InstallCWProxyImpl(this._value);

  final Install _value;

  @override
  Install systemKw(num systemKw) => this(systemKw: systemKw);

  @override
  Install place(String place) => this(place: place);

  @override
  Install stageIndex(int stageIndex) => this(stageIndex: stageIndex);

  @override
  Install stageCount(int stageCount) => this(stageCount: stageCount);

  @override
  Install total(int total) => this(total: total);

  @override
  Install subsidy(int subsidy) => this(subsidy: subsidy);

  @override
  Install handedOverOn(String? handedOverOn) =>
      this(handedOverOn: handedOverOn);

  @override
  Install upiUri(String? upiUri) => this(upiUri: upiUri);

  @override
  Install nextVisit(InstallNextVisit? nextVisit) => this(nextVisit: nextVisit);

  @override
  Install stages(List<InstallStage> stages) => this(stages: stages);

  @override
  Install payments(List<InstallPayment> payments) => this(payments: payments);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `Install(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// Install(...).copyWith(id: 12, name: "My name")
  /// ````
  Install call({
    Object? systemKw = const $CopyWithPlaceholder(),
    Object? place = const $CopyWithPlaceholder(),
    Object? stageIndex = const $CopyWithPlaceholder(),
    Object? stageCount = const $CopyWithPlaceholder(),
    Object? total = const $CopyWithPlaceholder(),
    Object? subsidy = const $CopyWithPlaceholder(),
    Object? handedOverOn = const $CopyWithPlaceholder(),
    Object? upiUri = const $CopyWithPlaceholder(),
    Object? nextVisit = const $CopyWithPlaceholder(),
    Object? stages = const $CopyWithPlaceholder(),
    Object? payments = const $CopyWithPlaceholder(),
  }) {
    return Install(
      systemKw: systemKw == const $CopyWithPlaceholder()
          ? _value.systemKw
          // ignore: cast_nullable_to_non_nullable
          : systemKw as num,
      place: place == const $CopyWithPlaceholder()
          ? _value.place
          // ignore: cast_nullable_to_non_nullable
          : place as String,
      stageIndex: stageIndex == const $CopyWithPlaceholder()
          ? _value.stageIndex
          // ignore: cast_nullable_to_non_nullable
          : stageIndex as int,
      stageCount: stageCount == const $CopyWithPlaceholder()
          ? _value.stageCount
          // ignore: cast_nullable_to_non_nullable
          : stageCount as int,
      total: total == const $CopyWithPlaceholder()
          ? _value.total
          // ignore: cast_nullable_to_non_nullable
          : total as int,
      subsidy: subsidy == const $CopyWithPlaceholder()
          ? _value.subsidy
          // ignore: cast_nullable_to_non_nullable
          : subsidy as int,
      handedOverOn: handedOverOn == const $CopyWithPlaceholder()
          ? _value.handedOverOn
          // ignore: cast_nullable_to_non_nullable
          : handedOverOn as String?,
      upiUri: upiUri == const $CopyWithPlaceholder()
          ? _value.upiUri
          // ignore: cast_nullable_to_non_nullable
          : upiUri as String?,
      nextVisit: nextVisit == const $CopyWithPlaceholder()
          ? _value.nextVisit
          // ignore: cast_nullable_to_non_nullable
          : nextVisit as InstallNextVisit?,
      stages: stages == const $CopyWithPlaceholder()
          ? _value.stages
          // ignore: cast_nullable_to_non_nullable
          : stages as List<InstallStage>,
      payments: payments == const $CopyWithPlaceholder()
          ? _value.payments
          // ignore: cast_nullable_to_non_nullable
          : payments as List<InstallPayment>,
    );
  }
}

extension $InstallCopyWith on Install {
  /// Returns a callable class that can be used as follows: `instanceOfInstall.copyWith(...)` or like so:`instanceOfInstall.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$InstallCWProxy get copyWith => _$InstallCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Install _$InstallFromJson(Map<String, dynamic> json) => $checkedCreate(
  'Install',
  json,
  ($checkedConvert) {
    $checkKeys(
      json,
      requiredKeys: const [
        'system_kw',
        'place',
        'stage_index',
        'stage_count',
        'total',
        'subsidy',
        'stages',
        'payments',
      ],
    );
    final val = Install(
      systemKw: $checkedConvert('system_kw', (v) => v as num),
      place: $checkedConvert('place', (v) => v as String),
      stageIndex: $checkedConvert('stage_index', (v) => (v as num).toInt()),
      stageCount: $checkedConvert('stage_count', (v) => (v as num).toInt()),
      total: $checkedConvert('total', (v) => (v as num).toInt()),
      subsidy: $checkedConvert('subsidy', (v) => (v as num).toInt()),
      handedOverOn: $checkedConvert('handed_over_on', (v) => v as String?),
      upiUri: $checkedConvert('upi_uri', (v) => v as String?),
      nextVisit: $checkedConvert(
        'next_visit',
        (v) => v == null
            ? null
            : InstallNextVisit.fromJson(v as Map<String, dynamic>),
      ),
      stages: $checkedConvert(
        'stages',
        (v) => (v as List<dynamic>)
            .map((e) => InstallStage.fromJson(e as Map<String, dynamic>))
            .toList(),
      ),
      payments: $checkedConvert(
        'payments',
        (v) => (v as List<dynamic>)
            .map((e) => InstallPayment.fromJson(e as Map<String, dynamic>))
            .toList(),
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'systemKw': 'system_kw',
    'stageIndex': 'stage_index',
    'stageCount': 'stage_count',
    'handedOverOn': 'handed_over_on',
    'upiUri': 'upi_uri',
    'nextVisit': 'next_visit',
  },
);

Map<String, dynamic> _$InstallToJson(Install instance) => <String, dynamic>{
  'system_kw': instance.systemKw,
  'place': instance.place,
  'stage_index': instance.stageIndex,
  'stage_count': instance.stageCount,
  'total': instance.total,
  'subsidy': instance.subsidy,
  'handed_over_on': ?instance.handedOverOn,
  'upi_uri': ?instance.upiUri,
  'next_visit': ?instance.nextVisit?.toJson(),
  'stages': instance.stages.map((e) => e.toJson()).toList(),
  'payments': instance.payments.map((e) => e.toJson()).toList(),
};
