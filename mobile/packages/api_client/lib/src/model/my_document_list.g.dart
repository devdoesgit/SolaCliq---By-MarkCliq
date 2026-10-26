// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'my_document_list.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$MyDocumentListCWProxy {
  MyDocumentList items(List<MyDocument> items);

  MyDocumentList uploadedBy(String? uploadedBy);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `MyDocumentList(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// MyDocumentList(...).copyWith(id: 12, name: "My name")
  /// ````
  MyDocumentList call({List<MyDocument> items, String? uploadedBy});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfMyDocumentList.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfMyDocumentList.copyWith.fieldName(...)`
class _$MyDocumentListCWProxyImpl implements _$MyDocumentListCWProxy {
  const _$MyDocumentListCWProxyImpl(this._value);

  final MyDocumentList _value;

  @override
  MyDocumentList items(List<MyDocument> items) => this(items: items);

  @override
  MyDocumentList uploadedBy(String? uploadedBy) => this(uploadedBy: uploadedBy);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `MyDocumentList(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// MyDocumentList(...).copyWith(id: 12, name: "My name")
  /// ````
  MyDocumentList call({
    Object? items = const $CopyWithPlaceholder(),
    Object? uploadedBy = const $CopyWithPlaceholder(),
  }) {
    return MyDocumentList(
      items: items == const $CopyWithPlaceholder()
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<MyDocument>,
      uploadedBy: uploadedBy == const $CopyWithPlaceholder()
          ? _value.uploadedBy
          // ignore: cast_nullable_to_non_nullable
          : uploadedBy as String?,
    );
  }
}

extension $MyDocumentListCopyWith on MyDocumentList {
  /// Returns a callable class that can be used as follows: `instanceOfMyDocumentList.copyWith(...)` or like so:`instanceOfMyDocumentList.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$MyDocumentListCWProxy get copyWith => _$MyDocumentListCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MyDocumentList _$MyDocumentListFromJson(Map<String, dynamic> json) =>
    $checkedCreate('MyDocumentList', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['items']);
      final val = MyDocumentList(
        items: $checkedConvert(
          'items',
          (v) => (v as List<dynamic>)
              .map((e) => MyDocument.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
        uploadedBy: $checkedConvert('uploaded_by', (v) => v as String?),
      );
      return val;
    }, fieldKeyMap: const {'uploadedBy': 'uploaded_by'});

Map<String, dynamic> _$MyDocumentListToJson(MyDocumentList instance) =>
    <String, dynamic>{
      'items': instance.items.map((e) => e.toJson()).toList(),
      'uploaded_by': ?instance.uploadedBy,
    };
