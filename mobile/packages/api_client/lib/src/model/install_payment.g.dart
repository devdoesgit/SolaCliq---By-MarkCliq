// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'install_payment.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$InstallPaymentCWProxy {
  InstallPayment id(String id);

  InstallPayment label(String label);

  InstallPayment detail(String? detail);

  InstallPayment amount(int amount);

  InstallPayment dueOn(String? dueOn);

  InstallPayment status(InstallPaymentStatusEnum status);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `InstallPayment(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// InstallPayment(...).copyWith(id: 12, name: "My name")
  /// ````
  InstallPayment call({
    String id,
    String label,
    String? detail,
    int amount,
    String? dueOn,
    InstallPaymentStatusEnum status,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfInstallPayment.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfInstallPayment.copyWith.fieldName(...)`
class _$InstallPaymentCWProxyImpl implements _$InstallPaymentCWProxy {
  const _$InstallPaymentCWProxyImpl(this._value);

  final InstallPayment _value;

  @override
  InstallPayment id(String id) => this(id: id);

  @override
  InstallPayment label(String label) => this(label: label);

  @override
  InstallPayment detail(String? detail) => this(detail: detail);

  @override
  InstallPayment amount(int amount) => this(amount: amount);

  @override
  InstallPayment dueOn(String? dueOn) => this(dueOn: dueOn);

  @override
  InstallPayment status(InstallPaymentStatusEnum status) =>
      this(status: status);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `InstallPayment(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// InstallPayment(...).copyWith(id: 12, name: "My name")
  /// ````
  InstallPayment call({
    Object? id = const $CopyWithPlaceholder(),
    Object? label = const $CopyWithPlaceholder(),
    Object? detail = const $CopyWithPlaceholder(),
    Object? amount = const $CopyWithPlaceholder(),
    Object? dueOn = const $CopyWithPlaceholder(),
    Object? status = const $CopyWithPlaceholder(),
  }) {
    return InstallPayment(
      id: id == const $CopyWithPlaceholder()
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      label: label == const $CopyWithPlaceholder()
          ? _value.label
          // ignore: cast_nullable_to_non_nullable
          : label as String,
      detail: detail == const $CopyWithPlaceholder()
          ? _value.detail
          // ignore: cast_nullable_to_non_nullable
          : detail as String?,
      amount: amount == const $CopyWithPlaceholder()
          ? _value.amount
          // ignore: cast_nullable_to_non_nullable
          : amount as int,
      dueOn: dueOn == const $CopyWithPlaceholder()
          ? _value.dueOn
          // ignore: cast_nullable_to_non_nullable
          : dueOn as String?,
      status: status == const $CopyWithPlaceholder()
          ? _value.status
          // ignore: cast_nullable_to_non_nullable
          : status as InstallPaymentStatusEnum,
    );
  }
}

extension $InstallPaymentCopyWith on InstallPayment {
  /// Returns a callable class that can be used as follows: `instanceOfInstallPayment.copyWith(...)` or like so:`instanceOfInstallPayment.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$InstallPaymentCWProxy get copyWith => _$InstallPaymentCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

InstallPayment _$InstallPaymentFromJson(Map<String, dynamic> json) =>
    $checkedCreate('InstallPayment', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['id', 'label', 'amount', 'status']);
      final val = InstallPayment(
        id: $checkedConvert('id', (v) => v as String),
        label: $checkedConvert('label', (v) => v as String),
        detail: $checkedConvert('detail', (v) => v as String?),
        amount: $checkedConvert('amount', (v) => (v as num).toInt()),
        dueOn: $checkedConvert('due_on', (v) => v as String?),
        status: $checkedConvert(
          'status',
          (v) => $enumDecode(_$InstallPaymentStatusEnumEnumMap, v),
        ),
      );
      return val;
    }, fieldKeyMap: const {'dueOn': 'due_on'});

Map<String, dynamic> _$InstallPaymentToJson(InstallPayment instance) =>
    <String, dynamic>{
      'id': instance.id,
      'label': instance.label,
      'detail': ?instance.detail,
      'amount': instance.amount,
      'due_on': ?instance.dueOn,
      'status': _$InstallPaymentStatusEnumEnumMap[instance.status]!,
    };

const _$InstallPaymentStatusEnumEnumMap = {
  InstallPaymentStatusEnum.due: 'due',
  InstallPaymentStatusEnum.claimed: 'claimed',
  InstallPaymentStatusEnum.paid: 'paid',
  InstallPaymentStatusEnum.later: 'later',
};
