// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'commission_totals.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$CommissionTotalsCWProxy {
  CommissionTotals inReview(int inReview);

  CommissionTotals waiting(int waiting);

  CommissionTotals payable(int payable);

  CommissionTotals paidThisMonth(int paidThisMonth);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `CommissionTotals(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// CommissionTotals(...).copyWith(id: 12, name: "My name")
  /// ````
  CommissionTotals call({
    int inReview,
    int waiting,
    int payable,
    int paidThisMonth,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfCommissionTotals.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfCommissionTotals.copyWith.fieldName(...)`
class _$CommissionTotalsCWProxyImpl implements _$CommissionTotalsCWProxy {
  const _$CommissionTotalsCWProxyImpl(this._value);

  final CommissionTotals _value;

  @override
  CommissionTotals inReview(int inReview) => this(inReview: inReview);

  @override
  CommissionTotals waiting(int waiting) => this(waiting: waiting);

  @override
  CommissionTotals payable(int payable) => this(payable: payable);

  @override
  CommissionTotals paidThisMonth(int paidThisMonth) =>
      this(paidThisMonth: paidThisMonth);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `CommissionTotals(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// CommissionTotals(...).copyWith(id: 12, name: "My name")
  /// ````
  CommissionTotals call({
    Object? inReview = const $CopyWithPlaceholder(),
    Object? waiting = const $CopyWithPlaceholder(),
    Object? payable = const $CopyWithPlaceholder(),
    Object? paidThisMonth = const $CopyWithPlaceholder(),
  }) {
    return CommissionTotals(
      inReview: inReview == const $CopyWithPlaceholder()
          ? _value.inReview
          // ignore: cast_nullable_to_non_nullable
          : inReview as int,
      waiting: waiting == const $CopyWithPlaceholder()
          ? _value.waiting
          // ignore: cast_nullable_to_non_nullable
          : waiting as int,
      payable: payable == const $CopyWithPlaceholder()
          ? _value.payable
          // ignore: cast_nullable_to_non_nullable
          : payable as int,
      paidThisMonth: paidThisMonth == const $CopyWithPlaceholder()
          ? _value.paidThisMonth
          // ignore: cast_nullable_to_non_nullable
          : paidThisMonth as int,
    );
  }
}

extension $CommissionTotalsCopyWith on CommissionTotals {
  /// Returns a callable class that can be used as follows: `instanceOfCommissionTotals.copyWith(...)` or like so:`instanceOfCommissionTotals.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$CommissionTotalsCWProxy get copyWith => _$CommissionTotalsCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CommissionTotals _$CommissionTotalsFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'CommissionTotals',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'in_review',
            'waiting',
            'payable',
            'paid_this_month',
          ],
        );
        final val = CommissionTotals(
          inReview: $checkedConvert('in_review', (v) => (v as num).toInt()),
          waiting: $checkedConvert('waiting', (v) => (v as num).toInt()),
          payable: $checkedConvert('payable', (v) => (v as num).toInt()),
          paidThisMonth: $checkedConvert(
            'paid_this_month',
            (v) => (v as num).toInt(),
          ),
        );
        return val;
      },
      fieldKeyMap: const {
        'inReview': 'in_review',
        'paidThisMonth': 'paid_this_month',
      },
    );

Map<String, dynamic> _$CommissionTotalsToJson(CommissionTotals instance) =>
    <String, dynamic>{
      'in_review': instance.inReview,
      'waiting': instance.waiting,
      'payable': instance.payable,
      'paid_this_month': instance.paidThisMonth,
    };
