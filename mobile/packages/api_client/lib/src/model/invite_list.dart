//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api_client/src/model/invite.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'invite_list.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class InviteList {
  /// Returns a new [InviteList] instance.
  InviteList({required this.items});

  @JsonKey(name: r'items', required: true, includeIfNull: false)
  final List<Invite> items;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is InviteList &&
            runtimeType == other.runtimeType &&
            equals([items], [other.items]);
  }

  @override
  int get hashCode => runtimeType.hashCode ^ mapPropsToHashCode([items]);

  factory InviteList.fromJson(Map<String, dynamic> json) =>
      _$InviteListFromJson(json);

  Map<String, dynamic> toJson() => _$InviteListToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
