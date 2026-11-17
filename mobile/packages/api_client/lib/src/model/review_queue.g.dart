// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'review_queue.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ReviewQueueCWProxy {
  ReviewQueue commissions(List<ReviewItem> commissions);

  ReviewQueue expenses(List<ReviewItem> expenses);

  ReviewQueue payments(List<ReviewItem> payments);

  ReviewQueue registrations(List<ReviewItem> registrations);

  ReviewQueue tasks(List<ReviewItem> tasks);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ReviewQueue(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ReviewQueue(...).copyWith(id: 12, name: "My name")
  /// ````
  ReviewQueue call({
    List<ReviewItem> commissions,
    List<ReviewItem> expenses,
    List<ReviewItem> payments,
    List<ReviewItem> registrations,
    List<ReviewItem> tasks,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfReviewQueue.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfReviewQueue.copyWith.fieldName(...)`
class _$ReviewQueueCWProxyImpl implements _$ReviewQueueCWProxy {
  const _$ReviewQueueCWProxyImpl(this._value);

  final ReviewQueue _value;

  @override
  ReviewQueue commissions(List<ReviewItem> commissions) =>
      this(commissions: commissions);

  @override
  ReviewQueue expenses(List<ReviewItem> expenses) => this(expenses: expenses);

  @override
  ReviewQueue payments(List<ReviewItem> payments) => this(payments: payments);

  @override
  ReviewQueue registrations(List<ReviewItem> registrations) =>
      this(registrations: registrations);

  @override
  ReviewQueue tasks(List<ReviewItem> tasks) => this(tasks: tasks);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ReviewQueue(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ReviewQueue(...).copyWith(id: 12, name: "My name")
  /// ````
  ReviewQueue call({
    Object? commissions = const $CopyWithPlaceholder(),
    Object? expenses = const $CopyWithPlaceholder(),
    Object? payments = const $CopyWithPlaceholder(),
    Object? registrations = const $CopyWithPlaceholder(),
    Object? tasks = const $CopyWithPlaceholder(),
  }) {
    return ReviewQueue(
      commissions: commissions == const $CopyWithPlaceholder()
          ? _value.commissions
          // ignore: cast_nullable_to_non_nullable
          : commissions as List<ReviewItem>,
      expenses: expenses == const $CopyWithPlaceholder()
          ? _value.expenses
          // ignore: cast_nullable_to_non_nullable
          : expenses as List<ReviewItem>,
      payments: payments == const $CopyWithPlaceholder()
          ? _value.payments
          // ignore: cast_nullable_to_non_nullable
          : payments as List<ReviewItem>,
      registrations: registrations == const $CopyWithPlaceholder()
          ? _value.registrations
          // ignore: cast_nullable_to_non_nullable
          : registrations as List<ReviewItem>,
      tasks: tasks == const $CopyWithPlaceholder()
          ? _value.tasks
          // ignore: cast_nullable_to_non_nullable
          : tasks as List<ReviewItem>,
    );
  }
}

extension $ReviewQueueCopyWith on ReviewQueue {
  /// Returns a callable class that can be used as follows: `instanceOfReviewQueue.copyWith(...)` or like so:`instanceOfReviewQueue.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ReviewQueueCWProxy get copyWith => _$ReviewQueueCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ReviewQueue _$ReviewQueueFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ReviewQueue', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const [
          'commissions',
          'expenses',
          'payments',
          'registrations',
          'tasks',
        ],
      );
      final val = ReviewQueue(
        commissions: $checkedConvert(
          'commissions',
          (v) => (v as List<dynamic>)
              .map((e) => ReviewItem.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
        expenses: $checkedConvert(
          'expenses',
          (v) => (v as List<dynamic>)
              .map((e) => ReviewItem.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
        payments: $checkedConvert(
          'payments',
          (v) => (v as List<dynamic>)
              .map((e) => ReviewItem.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
        registrations: $checkedConvert(
          'registrations',
          (v) => (v as List<dynamic>)
              .map((e) => ReviewItem.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
        tasks: $checkedConvert(
          'tasks',
          (v) => (v as List<dynamic>)
              .map((e) => ReviewItem.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$ReviewQueueToJson(ReviewQueue instance) =>
    <String, dynamic>{
      'commissions': instance.commissions.map((e) => e.toJson()).toList(),
      'expenses': instance.expenses.map((e) => e.toJson()).toList(),
      'payments': instance.payments.map((e) => e.toJson()).toList(),
      'registrations': instance.registrations.map((e) => e.toJson()).toList(),
      'tasks': instance.tasks.map((e) => e.toJson()).toList(),
    };
