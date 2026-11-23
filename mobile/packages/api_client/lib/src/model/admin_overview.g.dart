// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_overview.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$AdminOverviewCWProxy {
  AdminOverview today(String today);

  AdminOverview installsRunning(int installsRunning);

  AdminOverview byStage(List<int> byStage);

  AdminOverview collectedThisMonth(int collectedThisMonth);

  AdminOverview toCollect(int toCollect);

  AdminOverview finishedByWeek(List<FinishedWeek> finishedByWeek);

  AdminOverview commissions(CommissionTotals commissions);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `AdminOverview(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// AdminOverview(...).copyWith(id: 12, name: "My name")
  /// ````
  AdminOverview call({
    String today,
    int installsRunning,
    List<int> byStage,
    int collectedThisMonth,
    int toCollect,
    List<FinishedWeek> finishedByWeek,
    CommissionTotals commissions,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfAdminOverview.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfAdminOverview.copyWith.fieldName(...)`
class _$AdminOverviewCWProxyImpl implements _$AdminOverviewCWProxy {
  const _$AdminOverviewCWProxyImpl(this._value);

  final AdminOverview _value;

  @override
  AdminOverview today(String today) => this(today: today);

  @override
  AdminOverview installsRunning(int installsRunning) =>
      this(installsRunning: installsRunning);

  @override
  AdminOverview byStage(List<int> byStage) => this(byStage: byStage);

  @override
  AdminOverview collectedThisMonth(int collectedThisMonth) =>
      this(collectedThisMonth: collectedThisMonth);

  @override
  AdminOverview toCollect(int toCollect) => this(toCollect: toCollect);

  @override
  AdminOverview finishedByWeek(List<FinishedWeek> finishedByWeek) =>
      this(finishedByWeek: finishedByWeek);

  @override
  AdminOverview commissions(CommissionTotals commissions) =>
      this(commissions: commissions);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `AdminOverview(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// AdminOverview(...).copyWith(id: 12, name: "My name")
  /// ````
  AdminOverview call({
    Object? today = const $CopyWithPlaceholder(),
    Object? installsRunning = const $CopyWithPlaceholder(),
    Object? byStage = const $CopyWithPlaceholder(),
    Object? collectedThisMonth = const $CopyWithPlaceholder(),
    Object? toCollect = const $CopyWithPlaceholder(),
    Object? finishedByWeek = const $CopyWithPlaceholder(),
    Object? commissions = const $CopyWithPlaceholder(),
  }) {
    return AdminOverview(
      today: today == const $CopyWithPlaceholder()
          ? _value.today
          // ignore: cast_nullable_to_non_nullable
          : today as String,
      installsRunning: installsRunning == const $CopyWithPlaceholder()
          ? _value.installsRunning
          // ignore: cast_nullable_to_non_nullable
          : installsRunning as int,
      byStage: byStage == const $CopyWithPlaceholder()
          ? _value.byStage
          // ignore: cast_nullable_to_non_nullable
          : byStage as List<int>,
      collectedThisMonth: collectedThisMonth == const $CopyWithPlaceholder()
          ? _value.collectedThisMonth
          // ignore: cast_nullable_to_non_nullable
          : collectedThisMonth as int,
      toCollect: toCollect == const $CopyWithPlaceholder()
          ? _value.toCollect
          // ignore: cast_nullable_to_non_nullable
          : toCollect as int,
      finishedByWeek: finishedByWeek == const $CopyWithPlaceholder()
          ? _value.finishedByWeek
          // ignore: cast_nullable_to_non_nullable
          : finishedByWeek as List<FinishedWeek>,
      commissions: commissions == const $CopyWithPlaceholder()
          ? _value.commissions
          // ignore: cast_nullable_to_non_nullable
          : commissions as CommissionTotals,
    );
  }
}

extension $AdminOverviewCopyWith on AdminOverview {
  /// Returns a callable class that can be used as follows: `instanceOfAdminOverview.copyWith(...)` or like so:`instanceOfAdminOverview.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$AdminOverviewCWProxy get copyWith => _$AdminOverviewCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AdminOverview _$AdminOverviewFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'AdminOverview',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'today',
            'installs_running',
            'by_stage',
            'collected_this_month',
            'to_collect',
            'finished_by_week',
            'commissions',
          ],
        );
        final val = AdminOverview(
          today: $checkedConvert('today', (v) => v as String),
          installsRunning: $checkedConvert(
            'installs_running',
            (v) => (v as num).toInt(),
          ),
          byStage: $checkedConvert(
            'by_stage',
            (v) => (v as List<dynamic>).map((e) => (e as num).toInt()).toList(),
          ),
          collectedThisMonth: $checkedConvert(
            'collected_this_month',
            (v) => (v as num).toInt(),
          ),
          toCollect: $checkedConvert('to_collect', (v) => (v as num).toInt()),
          finishedByWeek: $checkedConvert(
            'finished_by_week',
            (v) => (v as List<dynamic>)
                .map((e) => FinishedWeek.fromJson(e as Map<String, dynamic>))
                .toList(),
          ),
          commissions: $checkedConvert(
            'commissions',
            (v) => CommissionTotals.fromJson(v as Map<String, dynamic>),
          ),
        );
        return val;
      },
      fieldKeyMap: const {
        'installsRunning': 'installs_running',
        'byStage': 'by_stage',
        'collectedThisMonth': 'collected_this_month',
        'toCollect': 'to_collect',
        'finishedByWeek': 'finished_by_week',
      },
    );

Map<String, dynamic> _$AdminOverviewToJson(
  AdminOverview instance,
) => <String, dynamic>{
  'today': instance.today,
  'installs_running': instance.installsRunning,
  'by_stage': instance.byStage,
  'collected_this_month': instance.collectedThisMonth,
  'to_collect': instance.toCollect,
  'finished_by_week': instance.finishedByWeek.map((e) => e.toJson()).toList(),
  'commissions': instance.commissions.toJson(),
};
