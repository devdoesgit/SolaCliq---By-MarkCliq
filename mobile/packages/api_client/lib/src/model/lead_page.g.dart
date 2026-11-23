// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lead_page.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$LeadPageCWProxy {
  LeadPage items(List<LeadSummary> items);

  LeadPage page(PageInfo page);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `LeadPage(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// LeadPage(...).copyWith(id: 12, name: "My name")
  /// ````
  LeadPage call({List<LeadSummary> items, PageInfo page});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfLeadPage.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfLeadPage.copyWith.fieldName(...)`
class _$LeadPageCWProxyImpl implements _$LeadPageCWProxy {
  const _$LeadPageCWProxyImpl(this._value);

  final LeadPage _value;

  @override
  LeadPage items(List<LeadSummary> items) => this(items: items);

  @override
  LeadPage page(PageInfo page) => this(page: page);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `LeadPage(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// LeadPage(...).copyWith(id: 12, name: "My name")
  /// ````
  LeadPage call({
    Object? items = const $CopyWithPlaceholder(),
    Object? page = const $CopyWithPlaceholder(),
  }) {
    return LeadPage(
      items: items == const $CopyWithPlaceholder()
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<LeadSummary>,
      page: page == const $CopyWithPlaceholder()
          ? _value.page
          // ignore: cast_nullable_to_non_nullable
          : page as PageInfo,
    );
  }
}

extension $LeadPageCopyWith on LeadPage {
  /// Returns a callable class that can be used as follows: `instanceOfLeadPage.copyWith(...)` or like so:`instanceOfLeadPage.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$LeadPageCWProxy get copyWith => _$LeadPageCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LeadPage _$LeadPageFromJson(Map<String, dynamic> json) =>
    $checkedCreate('LeadPage', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['items', 'page']);
      final val = LeadPage(
        items: $checkedConvert(
          'items',
          (v) => (v as List<dynamic>)
              .map((e) => LeadSummary.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
        page: $checkedConvert(
          'page',
          (v) => PageInfo.fromJson(v as Map<String, dynamic>),
        ),
      );
      return val;
    });

Map<String, dynamic> _$LeadPageToJson(LeadPage instance) => <String, dynamic>{
  'items': instance.items.map((e) => e.toJson()).toList(),
  'page': instance.page.toJson(),
};
