// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'invite_list.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$InviteListCWProxy {
  InviteList items(List<Invite> items);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `InviteList(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// InviteList(...).copyWith(id: 12, name: "My name")
  /// ````
  InviteList call({List<Invite> items});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfInviteList.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfInviteList.copyWith.fieldName(...)`
class _$InviteListCWProxyImpl implements _$InviteListCWProxy {
  const _$InviteListCWProxyImpl(this._value);

  final InviteList _value;

  @override
  InviteList items(List<Invite> items) => this(items: items);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `InviteList(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// InviteList(...).copyWith(id: 12, name: "My name")
  /// ````
  InviteList call({Object? items = const $CopyWithPlaceholder()}) {
    return InviteList(
      items: items == const $CopyWithPlaceholder()
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<Invite>,
    );
  }
}

extension $InviteListCopyWith on InviteList {
  /// Returns a callable class that can be used as follows: `instanceOfInviteList.copyWith(...)` or like so:`instanceOfInviteList.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$InviteListCWProxy get copyWith => _$InviteListCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

InviteList _$InviteListFromJson(Map<String, dynamic> json) =>
    $checkedCreate('InviteList', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['items']);
      final val = InviteList(
        items: $checkedConvert(
          'items',
          (v) => (v as List<dynamic>)
              .map((e) => Invite.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$InviteListToJson(InviteList instance) =>
    <String, dynamic>{'items': instance.items.map((e) => e.toJson()).toList()};
