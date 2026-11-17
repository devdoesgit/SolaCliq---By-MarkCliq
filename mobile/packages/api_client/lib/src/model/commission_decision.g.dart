// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'commission_decision.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$CommissionDecisionCWProxy {
  CommissionDecision amount(int? amount);

  CommissionDecision note(String? note);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `CommissionDecision(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// CommissionDecision(...).copyWith(id: 12, name: "My name")
  /// ````
  CommissionDecision call({int? amount, String? note});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfCommissionDecision.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfCommissionDecision.copyWith.fieldName(...)`
class _$CommissionDecisionCWProxyImpl implements _$CommissionDecisionCWProxy {
  const _$CommissionDecisionCWProxyImpl(this._value);

  final CommissionDecision _value;

  @override
  CommissionDecision amount(int? amount) => this(amount: amount);

  @override
  CommissionDecision note(String? note) => this(note: note);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `CommissionDecision(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// CommissionDecision(...).copyWith(id: 12, name: "My name")
  /// ````
  CommissionDecision call({
    Object? amount = const $CopyWithPlaceholder(),
    Object? note = const $CopyWithPlaceholder(),
  }) {
    return CommissionDecision(
      amount: amount == const $CopyWithPlaceholder()
          ? _value.amount
          // ignore: cast_nullable_to_non_nullable
          : amount as int?,
      note: note == const $CopyWithPlaceholder()
          ? _value.note
          // ignore: cast_nullable_to_non_nullable
          : note as String?,
    );
  }
}

extension $CommissionDecisionCopyWith on CommissionDecision {
  /// Returns a callable class that can be used as follows: `instanceOfCommissionDecision.copyWith(...)` or like so:`instanceOfCommissionDecision.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$CommissionDecisionCWProxy get copyWith =>
      _$CommissionDecisionCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CommissionDecision _$CommissionDecisionFromJson(Map<String, dynamic> json) =>
    $checkedCreate('CommissionDecision', json, ($checkedConvert) {
      final val = CommissionDecision(
        amount: $checkedConvert('amount', (v) => (v as num?)?.toInt()),
        note: $checkedConvert('note', (v) => v as String?),
      );
      return val;
    });

Map<String, dynamic> _$CommissionDecisionToJson(CommissionDecision instance) =>
    <String, dynamic>{'amount': ?instance.amount, 'note': ?instance.note};
