//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api_client/src/model/customer_summary.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'customer_list.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class CustomerList {
  /// Returns a new [CustomerList] instance.
  CustomerList({required this.items});

  @JsonKey(name: r'items', required: true, includeIfNull: false)
  final List<CustomerSummary> items;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is CustomerList &&
            runtimeType == other.runtimeType &&
            equals([items], [other.items]);
  }

  @override
  int get hashCode => runtimeType.hashCode ^ mapPropsToHashCode([items]);

  factory CustomerList.fromJson(Map<String, dynamic> json) =>
      _$CustomerListFromJson(json);

  Map<String, dynamic> toJson() => _$CustomerListToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
