//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'task_customer.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class TaskCustomer {
  /// Returns a new [TaskCustomer] instance.
  TaskCustomer({
    required this.name,

    this.systemKw,

    required this.address,

    this.phone,

    this.lat,

    this.lng,
  });

  @JsonKey(name: r'name', required: true, includeIfNull: false)
  final String name;

  @JsonKey(name: r'system_kw', required: false, includeIfNull: false)
  final num? systemKw;

  @JsonKey(name: r'address', required: true, includeIfNull: false)
  final String address;

  /// Indian mobile number, 10 digits, without +91.
  @JsonKey(name: r'phone', required: false, includeIfNull: false)
  final String? phone;

  @JsonKey(name: r'lat', required: false, includeIfNull: false)
  final num? lat;

  @JsonKey(name: r'lng', required: false, includeIfNull: false)
  final num? lng;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is TaskCustomer &&
            runtimeType == other.runtimeType &&
            equals(
              [name, systemKw, address, phone, lat, lng],
              [
                other.name,
                other.systemKw,
                other.address,
                other.phone,
                other.lat,
                other.lng,
              ],
            );
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^
      mapPropsToHashCode([name, systemKw, address, phone, lat, lng]);

  factory TaskCustomer.fromJson(Map<String, dynamic> json) =>
      _$TaskCustomerFromJson(json);

  Map<String, dynamic> toJson() => _$TaskCustomerToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
