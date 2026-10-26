// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payout_bank.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$PayoutBankCWProxy {
  PayoutBank holder(String? holder);

  PayoutBank accountNumber(String? accountNumber);

  PayoutBank accountLast4(String? accountLast4);

  PayoutBank ifsc(String? ifsc);

  PayoutBank bankName(String? bankName);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `PayoutBank(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// PayoutBank(...).copyWith(id: 12, name: "My name")
  /// ````
  PayoutBank call({
    String? holder,
    String? accountNumber,
    String? accountLast4,
    String? ifsc,
    String? bankName,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfPayoutBank.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfPayoutBank.copyWith.fieldName(...)`
class _$PayoutBankCWProxyImpl implements _$PayoutBankCWProxy {
  const _$PayoutBankCWProxyImpl(this._value);

  final PayoutBank _value;

  @override
  PayoutBank holder(String? holder) => this(holder: holder);

  @override
  PayoutBank accountNumber(String? accountNumber) =>
      this(accountNumber: accountNumber);

  @override
  PayoutBank accountLast4(String? accountLast4) =>
      this(accountLast4: accountLast4);

  @override
  PayoutBank ifsc(String? ifsc) => this(ifsc: ifsc);

  @override
  PayoutBank bankName(String? bankName) => this(bankName: bankName);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `PayoutBank(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// PayoutBank(...).copyWith(id: 12, name: "My name")
  /// ````
  PayoutBank call({
    Object? holder = const $CopyWithPlaceholder(),
    Object? accountNumber = const $CopyWithPlaceholder(),
    Object? accountLast4 = const $CopyWithPlaceholder(),
    Object? ifsc = const $CopyWithPlaceholder(),
    Object? bankName = const $CopyWithPlaceholder(),
  }) {
    return PayoutBank(
      holder: holder == const $CopyWithPlaceholder()
          ? _value.holder
          // ignore: cast_nullable_to_non_nullable
          : holder as String?,
      accountNumber: accountNumber == const $CopyWithPlaceholder()
          ? _value.accountNumber
          // ignore: cast_nullable_to_non_nullable
          : accountNumber as String?,
      accountLast4: accountLast4 == const $CopyWithPlaceholder()
          ? _value.accountLast4
          // ignore: cast_nullable_to_non_nullable
          : accountLast4 as String?,
      ifsc: ifsc == const $CopyWithPlaceholder()
          ? _value.ifsc
          // ignore: cast_nullable_to_non_nullable
          : ifsc as String?,
      bankName: bankName == const $CopyWithPlaceholder()
          ? _value.bankName
          // ignore: cast_nullable_to_non_nullable
          : bankName as String?,
    );
  }
}

extension $PayoutBankCopyWith on PayoutBank {
  /// Returns a callable class that can be used as follows: `instanceOfPayoutBank.copyWith(...)` or like so:`instanceOfPayoutBank.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$PayoutBankCWProxy get copyWith => _$PayoutBankCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PayoutBank _$PayoutBankFromJson(Map<String, dynamic> json) => $checkedCreate(
  'PayoutBank',
  json,
  ($checkedConvert) {
    final val = PayoutBank(
      holder: $checkedConvert('holder', (v) => v as String?),
      accountNumber: $checkedConvert('account_number', (v) => v as String?),
      accountLast4: $checkedConvert('account_last4', (v) => v as String?),
      ifsc: $checkedConvert('ifsc', (v) => v as String?),
      bankName: $checkedConvert('bank_name', (v) => v as String?),
    );
    return val;
  },
  fieldKeyMap: const {
    'accountNumber': 'account_number',
    'accountLast4': 'account_last4',
    'bankName': 'bank_name',
  },
);

Map<String, dynamic> _$PayoutBankToJson(PayoutBank instance) =>
    <String, dynamic>{
      'holder': ?instance.holder,
      'account_number': ?instance.accountNumber,
      'account_last4': ?instance.accountLast4,
      'ifsc': ?instance.ifsc,
      'bank_name': ?instance.bankName,
    };
