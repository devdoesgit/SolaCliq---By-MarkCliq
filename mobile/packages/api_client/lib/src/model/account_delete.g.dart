// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'account_delete.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$AccountDeleteCWProxy {
  AccountDelete password(String password);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `AccountDelete(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// AccountDelete(...).copyWith(id: 12, name: "My name")
  /// ````
  AccountDelete call({String password});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfAccountDelete.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfAccountDelete.copyWith.fieldName(...)`
class _$AccountDeleteCWProxyImpl implements _$AccountDeleteCWProxy {
  const _$AccountDeleteCWProxyImpl(this._value);

  final AccountDelete _value;

  @override
  AccountDelete password(String password) => this(password: password);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `AccountDelete(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// AccountDelete(...).copyWith(id: 12, name: "My name")
  /// ````
  AccountDelete call({Object? password = const $CopyWithPlaceholder()}) {
    return AccountDelete(
      password: password == const $CopyWithPlaceholder()
          ? _value.password
          // ignore: cast_nullable_to_non_nullable
          : password as String,
    );
  }
}

extension $AccountDeleteCopyWith on AccountDelete {
  /// Returns a callable class that can be used as follows: `instanceOfAccountDelete.copyWith(...)` or like so:`instanceOfAccountDelete.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$AccountDeleteCWProxy get copyWith => _$AccountDeleteCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AccountDelete _$AccountDeleteFromJson(Map<String, dynamic> json) =>
    $checkedCreate('AccountDelete', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['password']);
      final val = AccountDelete(
        password: $checkedConvert('password', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$AccountDeleteToJson(AccountDelete instance) =>
    <String, dynamic>{'password': instance.password};
