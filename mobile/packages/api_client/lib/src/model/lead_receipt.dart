//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'lead_receipt.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class LeadReceipt {
  /// Returns a new [LeadReceipt] instance.
  LeadReceipt({required this.id});

  /// UUIDv7.
  @JsonKey(name: r'id', required: true, includeIfNull: false)
  final String id;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is LeadReceipt &&
            runtimeType == other.runtimeType &&
            equals([id], [other.id]);
  }

  @override
  int get hashCode => runtimeType.hashCode ^ mapPropsToHashCode([id]);

  factory LeadReceipt.fromJson(Map<String, dynamic> json) =>
      _$LeadReceiptFromJson(json);

  Map<String, dynamic> toJson() => _$LeadReceiptToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
