//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'account_delete.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AccountDelete {
  /// Returns a new [AccountDelete] instance.
  AccountDelete({required this.password});

  @JsonKey(name: r'password', required: true, includeIfNull: false)
  final String password;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is AccountDelete &&
            runtimeType == other.runtimeType &&
            equals([password], [other.password]);
  }

  @override
  int get hashCode => runtimeType.hashCode ^ mapPropsToHashCode([password]);

  factory AccountDelete.fromJson(Map<String, dynamic> json) =>
      _$AccountDeleteFromJson(json);

  Map<String, dynamic> toJson() => _$AccountDeleteToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
