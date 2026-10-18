// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'member_page.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$MemberPageCWProxy {
  MemberPage items(List<Member> items);

  MemberPage page(PageInfo page);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `MemberPage(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// MemberPage(...).copyWith(id: 12, name: "My name")
  /// ````
  MemberPage call({List<Member> items, PageInfo page});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfMemberPage.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfMemberPage.copyWith.fieldName(...)`
class _$MemberPageCWProxyImpl implements _$MemberPageCWProxy {
  const _$MemberPageCWProxyImpl(this._value);

  final MemberPage _value;

  @override
  MemberPage items(List<Member> items) => this(items: items);

  @override
  MemberPage page(PageInfo page) => this(page: page);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `MemberPage(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// MemberPage(...).copyWith(id: 12, name: "My name")
  /// ````
  MemberPage call({
    Object? items = const $CopyWithPlaceholder(),
    Object? page = const $CopyWithPlaceholder(),
  }) {
    return MemberPage(
      items: items == const $CopyWithPlaceholder()
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<Member>,
      page: page == const $CopyWithPlaceholder()
          ? _value.page
          // ignore: cast_nullable_to_non_nullable
          : page as PageInfo,
    );
  }
}

extension $MemberPageCopyWith on MemberPage {
  /// Returns a callable class that can be used as follows: `instanceOfMemberPage.copyWith(...)` or like so:`instanceOfMemberPage.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$MemberPageCWProxy get copyWith => _$MemberPageCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MemberPage _$MemberPageFromJson(Map<String, dynamic> json) =>
    $checkedCreate('MemberPage', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['items', 'page']);
      final val = MemberPage(
        items: $checkedConvert(
          'items',
          (v) => (v as List<dynamic>)
              .map((e) => Member.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
        page: $checkedConvert(
          'page',
          (v) => PageInfo.fromJson(v as Map<String, dynamic>),
        ),
      );
      return val;
    });

Map<String, dynamic> _$MemberPageToJson(MemberPage instance) =>
    <String, dynamic>{
      'items': instance.items.map((e) => e.toJson()).toList(),
      'page': instance.page.toJson(),
    };
