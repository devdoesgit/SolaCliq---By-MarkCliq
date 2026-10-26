//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'access_request_create.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AccessRequestCreate {
  /// Returns a new [AccessRequestCreate] instance.
  AccessRequestCreate({
    required this.companyName,

    required this.ownerName,

    required this.phone,

    required this.city,

    required this.email,
  });

  @JsonKey(name: r'company_name', required: true, includeIfNull: false)
  final String companyName;

  @JsonKey(name: r'owner_name', required: true, includeIfNull: false)
  final String ownerName;

  /// Indian mobile number, 10 digits, without +91.
  @JsonKey(name: r'phone', required: true, includeIfNull: false)
  final String phone;

  @JsonKey(name: r'city', required: true, includeIfNull: false)
  final String city;

  @JsonKey(name: r'email', required: true, includeIfNull: false)
  final String email;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is AccessRequestCreate &&
            runtimeType == other.runtimeType &&
            equals(
              [companyName, ownerName, phone, city, email],
              [
                other.companyName,
                other.ownerName,
                other.phone,
                other.city,
                other.email,
              ],
            );
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^
      mapPropsToHashCode([companyName, ownerName, phone, city, email]);

  factory AccessRequestCreate.fromJson(Map<String, dynamic> json) =>
      _$AccessRequestCreateFromJson(json);

  Map<String, dynamic> toJson() => _$AccessRequestCreateToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
