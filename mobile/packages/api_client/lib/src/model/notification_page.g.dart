// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_page.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$NotificationPageCWProxy {
  NotificationPage items(List<Notification> items);

  NotificationPage unreadCount(int unreadCount);

  NotificationPage page(PageInfo page);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `NotificationPage(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// NotificationPage(...).copyWith(id: 12, name: "My name")
  /// ````
  NotificationPage call({
    List<Notification> items,
    int unreadCount,
    PageInfo page,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfNotificationPage.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfNotificationPage.copyWith.fieldName(...)`
class _$NotificationPageCWProxyImpl implements _$NotificationPageCWProxy {
  const _$NotificationPageCWProxyImpl(this._value);

  final NotificationPage _value;

  @override
  NotificationPage items(List<Notification> items) => this(items: items);

  @override
  NotificationPage unreadCount(int unreadCount) =>
      this(unreadCount: unreadCount);

  @override
  NotificationPage page(PageInfo page) => this(page: page);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `NotificationPage(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// NotificationPage(...).copyWith(id: 12, name: "My name")
  /// ````
  NotificationPage call({
    Object? items = const $CopyWithPlaceholder(),
    Object? unreadCount = const $CopyWithPlaceholder(),
    Object? page = const $CopyWithPlaceholder(),
  }) {
    return NotificationPage(
      items: items == const $CopyWithPlaceholder()
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<Notification>,
      unreadCount: unreadCount == const $CopyWithPlaceholder()
          ? _value.unreadCount
          // ignore: cast_nullable_to_non_nullable
          : unreadCount as int,
      page: page == const $CopyWithPlaceholder()
          ? _value.page
          // ignore: cast_nullable_to_non_nullable
          : page as PageInfo,
    );
  }
}

extension $NotificationPageCopyWith on NotificationPage {
  /// Returns a callable class that can be used as follows: `instanceOfNotificationPage.copyWith(...)` or like so:`instanceOfNotificationPage.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$NotificationPageCWProxy get copyWith => _$NotificationPageCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NotificationPage _$NotificationPageFromJson(Map<String, dynamic> json) =>
    $checkedCreate('NotificationPage', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['items', 'unread_count', 'page']);
      final val = NotificationPage(
        items: $checkedConvert(
          'items',
          (v) => (v as List<dynamic>)
              .map((e) => Notification.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
        unreadCount: $checkedConvert('unread_count', (v) => (v as num).toInt()),
        page: $checkedConvert(
          'page',
          (v) => PageInfo.fromJson(v as Map<String, dynamic>),
        ),
      );
      return val;
    }, fieldKeyMap: const {'unreadCount': 'unread_count'});

Map<String, dynamic> _$NotificationPageToJson(NotificationPage instance) =>
    <String, dynamic>{
      'items': instance.items.map((e) => e.toJson()).toList(),
      'unread_count': instance.unreadCount,
      'page': instance.page.toJson(),
    };
