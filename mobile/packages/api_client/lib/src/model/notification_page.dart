//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api_client/src/model/notification.dart';
import 'package:api_client/src/model/page_info.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'notification_page.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class NotificationPage {
  /// Returns a new [NotificationPage] instance.
  NotificationPage({
    required this.items,

    required this.unreadCount,

    required this.page,
  });

  @JsonKey(name: r'items', required: true, includeIfNull: false)
  final List<Notification> items;

  // minimum: 0
  @JsonKey(name: r'unread_count', required: true, includeIfNull: false)
  final int unreadCount;

  @JsonKey(name: r'page', required: true, includeIfNull: false)
  final PageInfo page;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is NotificationPage &&
            runtimeType == other.runtimeType &&
            equals(
              [items, unreadCount, page],
              [other.items, other.unreadCount, other.page],
            );
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^ mapPropsToHashCode([items, unreadCount, page]);

  factory NotificationPage.fromJson(Map<String, dynamic> json) =>
      _$NotificationPageFromJson(json);

  Map<String, dynamic> toJson() => _$NotificationPageToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
