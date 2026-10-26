// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'worker_stats.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$WorkerStatsCWProxy {
  WorkerStats tasksThisMonth(int tasksThisMonth);

  WorkerStats returnedThisMonth(int returnedThisMonth);

  WorkerStats avgMinutesOnSite(int avgMinutesOnSite);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `WorkerStats(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// WorkerStats(...).copyWith(id: 12, name: "My name")
  /// ````
  WorkerStats call({
    int tasksThisMonth,
    int returnedThisMonth,
    int avgMinutesOnSite,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfWorkerStats.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfWorkerStats.copyWith.fieldName(...)`
class _$WorkerStatsCWProxyImpl implements _$WorkerStatsCWProxy {
  const _$WorkerStatsCWProxyImpl(this._value);

  final WorkerStats _value;

  @override
  WorkerStats tasksThisMonth(int tasksThisMonth) =>
      this(tasksThisMonth: tasksThisMonth);

  @override
  WorkerStats returnedThisMonth(int returnedThisMonth) =>
      this(returnedThisMonth: returnedThisMonth);

  @override
  WorkerStats avgMinutesOnSite(int avgMinutesOnSite) =>
      this(avgMinutesOnSite: avgMinutesOnSite);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `WorkerStats(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// WorkerStats(...).copyWith(id: 12, name: "My name")
  /// ````
  WorkerStats call({
    Object? tasksThisMonth = const $CopyWithPlaceholder(),
    Object? returnedThisMonth = const $CopyWithPlaceholder(),
    Object? avgMinutesOnSite = const $CopyWithPlaceholder(),
  }) {
    return WorkerStats(
      tasksThisMonth: tasksThisMonth == const $CopyWithPlaceholder()
          ? _value.tasksThisMonth
          // ignore: cast_nullable_to_non_nullable
          : tasksThisMonth as int,
      returnedThisMonth: returnedThisMonth == const $CopyWithPlaceholder()
          ? _value.returnedThisMonth
          // ignore: cast_nullable_to_non_nullable
          : returnedThisMonth as int,
      avgMinutesOnSite: avgMinutesOnSite == const $CopyWithPlaceholder()
          ? _value.avgMinutesOnSite
          // ignore: cast_nullable_to_non_nullable
          : avgMinutesOnSite as int,
    );
  }
}

extension $WorkerStatsCopyWith on WorkerStats {
  /// Returns a callable class that can be used as follows: `instanceOfWorkerStats.copyWith(...)` or like so:`instanceOfWorkerStats.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$WorkerStatsCWProxy get copyWith => _$WorkerStatsCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WorkerStats _$WorkerStatsFromJson(Map<String, dynamic> json) => $checkedCreate(
  'WorkerStats',
  json,
  ($checkedConvert) {
    $checkKeys(
      json,
      requiredKeys: const [
        'tasks_this_month',
        'returned_this_month',
        'avg_minutes_on_site',
      ],
    );
    final val = WorkerStats(
      tasksThisMonth: $checkedConvert(
        'tasks_this_month',
        (v) => (v as num).toInt(),
      ),
      returnedThisMonth: $checkedConvert(
        'returned_this_month',
        (v) => (v as num).toInt(),
      ),
      avgMinutesOnSite: $checkedConvert(
        'avg_minutes_on_site',
        (v) => (v as num).toInt(),
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'tasksThisMonth': 'tasks_this_month',
    'returnedThisMonth': 'returned_this_month',
    'avgMinutesOnSite': 'avg_minutes_on_site',
  },
);

Map<String, dynamic> _$WorkerStatsToJson(WorkerStats instance) =>
    <String, dynamic>{
      'tasks_this_month': instance.tasksThisMonth,
      'returned_this_month': instance.returnedThisMonth,
      'avg_minutes_on_site': instance.avgMinutesOnSite,
    };
