// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'review_item.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ReviewItemCWProxy {
  ReviewItem at(DateTime at);

  ReviewItem id(String id);

  ReviewItem person(String person);

  ReviewItem reference(String reference);

  ReviewItem status(String status);

  ReviewItem title(String title);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ReviewItem(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ReviewItem(...).copyWith(id: 12, name: "My name")
  /// ````
  ReviewItem call({
    DateTime at,
    String id,
    String person,
    String reference,
    String status,
    String title,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfReviewItem.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfReviewItem.copyWith.fieldName(...)`
class _$ReviewItemCWProxyImpl implements _$ReviewItemCWProxy {
  const _$ReviewItemCWProxyImpl(this._value);

  final ReviewItem _value;

  @override
  ReviewItem at(DateTime at) => this(at: at);

  @override
  ReviewItem id(String id) => this(id: id);

  @override
  ReviewItem person(String person) => this(person: person);

  @override
  ReviewItem reference(String reference) => this(reference: reference);

  @override
  ReviewItem status(String status) => this(status: status);

  @override
  ReviewItem title(String title) => this(title: title);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ReviewItem(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ReviewItem(...).copyWith(id: 12, name: "My name")
  /// ````
  ReviewItem call({
    Object? at = const $CopyWithPlaceholder(),
    Object? id = const $CopyWithPlaceholder(),
    Object? person = const $CopyWithPlaceholder(),
    Object? reference = const $CopyWithPlaceholder(),
    Object? status = const $CopyWithPlaceholder(),
    Object? title = const $CopyWithPlaceholder(),
  }) {
    return ReviewItem(
      at: at == const $CopyWithPlaceholder()
          ? _value.at
          // ignore: cast_nullable_to_non_nullable
          : at as DateTime,
      id: id == const $CopyWithPlaceholder()
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      person: person == const $CopyWithPlaceholder()
          ? _value.person
          // ignore: cast_nullable_to_non_nullable
          : person as String,
      reference: reference == const $CopyWithPlaceholder()
          ? _value.reference
          // ignore: cast_nullable_to_non_nullable
          : reference as String,
      status: status == const $CopyWithPlaceholder()
          ? _value.status
          // ignore: cast_nullable_to_non_nullable
          : status as String,
      title: title == const $CopyWithPlaceholder()
          ? _value.title
          // ignore: cast_nullable_to_non_nullable
          : title as String,
    );
  }
}

extension $ReviewItemCopyWith on ReviewItem {
  /// Returns a callable class that can be used as follows: `instanceOfReviewItem.copyWith(...)` or like so:`instanceOfReviewItem.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ReviewItemCWProxy get copyWith => _$ReviewItemCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ReviewItem _$ReviewItemFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ReviewItem', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const [
          'at',
          'id',
          'person',
          'reference',
          'status',
          'title',
        ],
      );
      final val = ReviewItem(
        at: $checkedConvert('at', (v) => DateTime.parse(v as String)),
        id: $checkedConvert('id', (v) => v as String),
        person: $checkedConvert('person', (v) => v as String),
        reference: $checkedConvert('reference', (v) => v as String),
        status: $checkedConvert('status', (v) => v as String),
        title: $checkedConvert('title', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$ReviewItemToJson(ReviewItem instance) =>
    <String, dynamic>{
      'at': instance.at.toIso8601String(),
      'id': instance.id,
      'person': instance.person,
      'reference': instance.reference,
      'status': instance.status,
      'title': instance.title,
    };
