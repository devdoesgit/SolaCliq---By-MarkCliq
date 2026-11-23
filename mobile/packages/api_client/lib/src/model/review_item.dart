//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/src/equatable_utils.dart';

part 'review_item.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ReviewItem {
  /// Returns a new [ReviewItem] instance.
  ReviewItem({
    required this.at,

    required this.id,

    required this.person,

    required this.reference,

    required this.status,

    required this.title,

    this.amount,
  });

  @JsonKey(name: r'at', required: true, includeIfNull: false)
  final DateTime at;

  @JsonKey(name: r'id', required: true, includeIfNull: false)
  final String id;

  @JsonKey(name: r'person', required: true, includeIfNull: false)
  final String person;

  @JsonKey(name: r'reference', required: true, includeIfNull: false)
  final String reference;

  @JsonKey(name: r'status', required: true, includeIfNull: false)
  final String status;

  @JsonKey(name: r'title', required: true, includeIfNull: false)
  final String title;

  /// Amount in paise (₹1 = 100). Never a float.
  @JsonKey(name: r'amount', required: false, includeIfNull: false)
  final int? amount;

  bool operator ==(Object other) {
    return identical(this, other) ||
        other is ReviewItem &&
            runtimeType == other.runtimeType &&
            equals(
              [at, id, person, reference, status, title, amount],
              [
                other.at,
                other.id,
                other.person,
                other.reference,
                other.status,
                other.title,
                other.amount,
              ],
            );
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^
      mapPropsToHashCode([at, id, person, reference, status, title, amount]);

  factory ReviewItem.fromJson(Map<String, dynamic> json) =>
      _$ReviewItemFromJson(json);

  Map<String, dynamic> toJson() => _$ReviewItemToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
