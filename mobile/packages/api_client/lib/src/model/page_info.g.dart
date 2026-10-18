// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'page_info.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$PageInfoCWProxy {
  PageInfo nextCursor(String? nextCursor);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `PageInfo(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// PageInfo(...).copyWith(id: 12, name: "My name")
  /// ````
  PageInfo call({String? nextCursor});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfPageInfo.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfPageInfo.copyWith.fieldName(...)`
class _$PageInfoCWProxyImpl implements _$PageInfoCWProxy {
  const _$PageInfoCWProxyImpl(this._value);

  final PageInfo _value;

  @override
  PageInfo nextCursor(String? nextCursor) => this(nextCursor: nextCursor);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `PageInfo(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// PageInfo(...).copyWith(id: 12, name: "My name")
  /// ````
  PageInfo call({Object? nextCursor = const $CopyWithPlaceholder()}) {
    return PageInfo(
      nextCursor: nextCursor == const $CopyWithPlaceholder()
          ? _value.nextCursor
          // ignore: cast_nullable_to_non_nullable
          : nextCursor as String?,
    );
  }
}

extension $PageInfoCopyWith on PageInfo {
  /// Returns a callable class that can be used as follows: `instanceOfPageInfo.copyWith(...)` or like so:`instanceOfPageInfo.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$PageInfoCWProxy get copyWith => _$PageInfoCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PageInfo _$PageInfoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('PageInfo', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['next_cursor']);
      final val = PageInfo(
        nextCursor: $checkedConvert('next_cursor', (v) => v as String?),
      );
      return val;
    }, fieldKeyMap: const {'nextCursor': 'next_cursor'});

Map<String, dynamic> _$PageInfoToJson(PageInfo instance) => <String, dynamic>{
  'next_cursor': instance.nextCursor,
};
