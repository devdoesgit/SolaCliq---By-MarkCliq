// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_payment_page.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$AdminPaymentPageCWProxy {
  AdminPaymentPage items(List<AdminPayment> items);

  AdminPaymentPage page(PageInfo page);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `AdminPaymentPage(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// AdminPaymentPage(...).copyWith(id: 12, name: "My name")
  /// ````
  AdminPaymentPage call({List<AdminPayment> items, PageInfo page});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfAdminPaymentPage.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfAdminPaymentPage.copyWith.fieldName(...)`
class _$AdminPaymentPageCWProxyImpl implements _$AdminPaymentPageCWProxy {
  const _$AdminPaymentPageCWProxyImpl(this._value);

  final AdminPaymentPage _value;

  @override
  AdminPaymentPage items(List<AdminPayment> items) => this(items: items);

  @override
  AdminPaymentPage page(PageInfo page) => this(page: page);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `AdminPaymentPage(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// AdminPaymentPage(...).copyWith(id: 12, name: "My name")
  /// ````
  AdminPaymentPage call({
    Object? items = const $CopyWithPlaceholder(),
    Object? page = const $CopyWithPlaceholder(),
  }) {
    return AdminPaymentPage(
      items: items == const $CopyWithPlaceholder()
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<AdminPayment>,
      page: page == const $CopyWithPlaceholder()
          ? _value.page
          // ignore: cast_nullable_to_non_nullable
          : page as PageInfo,
    );
  }
}

extension $AdminPaymentPageCopyWith on AdminPaymentPage {
  /// Returns a callable class that can be used as follows: `instanceOfAdminPaymentPage.copyWith(...)` or like so:`instanceOfAdminPaymentPage.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$AdminPaymentPageCWProxy get copyWith => _$AdminPaymentPageCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AdminPaymentPage _$AdminPaymentPageFromJson(Map<String, dynamic> json) =>
    $checkedCreate('AdminPaymentPage', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['items', 'page']);
      final val = AdminPaymentPage(
        items: $checkedConvert(
          'items',
          (v) => (v as List<dynamic>)
              .map((e) => AdminPayment.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
        page: $checkedConvert(
          'page',
          (v) => PageInfo.fromJson(v as Map<String, dynamic>),
        ),
      );
      return val;
    });

Map<String, dynamic> _$AdminPaymentPageToJson(AdminPaymentPage instance) =>
    <String, dynamic>{
      'items': instance.items.map((e) => e.toJson()).toList(),
      'page': instance.page.toJson(),
    };
