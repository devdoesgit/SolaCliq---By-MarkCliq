// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'platform_org_page.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$PlatformOrgPageCWProxy {
  PlatformOrgPage items(List<PlatformOrg> items);

  PlatformOrgPage page(PageInfo page);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `PlatformOrgPage(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// PlatformOrgPage(...).copyWith(id: 12, name: "My name")
  /// ````
  PlatformOrgPage call({List<PlatformOrg> items, PageInfo page});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfPlatformOrgPage.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfPlatformOrgPage.copyWith.fieldName(...)`
class _$PlatformOrgPageCWProxyImpl implements _$PlatformOrgPageCWProxy {
  const _$PlatformOrgPageCWProxyImpl(this._value);

  final PlatformOrgPage _value;

  @override
  PlatformOrgPage items(List<PlatformOrg> items) => this(items: items);

  @override
  PlatformOrgPage page(PageInfo page) => this(page: page);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `PlatformOrgPage(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// PlatformOrgPage(...).copyWith(id: 12, name: "My name")
  /// ````
  PlatformOrgPage call({
    Object? items = const $CopyWithPlaceholder(),
    Object? page = const $CopyWithPlaceholder(),
  }) {
    return PlatformOrgPage(
      items: items == const $CopyWithPlaceholder()
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<PlatformOrg>,
      page: page == const $CopyWithPlaceholder()
          ? _value.page
          // ignore: cast_nullable_to_non_nullable
          : page as PageInfo,
    );
  }
}

extension $PlatformOrgPageCopyWith on PlatformOrgPage {
  /// Returns a callable class that can be used as follows: `instanceOfPlatformOrgPage.copyWith(...)` or like so:`instanceOfPlatformOrgPage.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$PlatformOrgPageCWProxy get copyWith => _$PlatformOrgPageCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PlatformOrgPage _$PlatformOrgPageFromJson(Map<String, dynamic> json) =>
    $checkedCreate('PlatformOrgPage', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['items', 'page']);
      final val = PlatformOrgPage(
        items: $checkedConvert(
          'items',
          (v) => (v as List<dynamic>)
              .map((e) => PlatformOrg.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
        page: $checkedConvert(
          'page',
          (v) => PageInfo.fromJson(v as Map<String, dynamic>),
        ),
      );
      return val;
    });

Map<String, dynamic> _$PlatformOrgPageToJson(PlatformOrgPage instance) =>
    <String, dynamic>{
      'items': instance.items.map((e) => e.toJson()).toList(),
      'page': instance.page.toJson(),
    };
