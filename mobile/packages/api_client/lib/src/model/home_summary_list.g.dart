// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'home_summary_list.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$HomeSummaryListCWProxy {
  HomeSummaryList title(String? title);

  HomeSummaryList rows(List<HomeRow> rows);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `HomeSummaryList(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// HomeSummaryList(...).copyWith(id: 12, name: "My name")
  /// ````
  HomeSummaryList call({String? title, List<HomeRow> rows});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfHomeSummaryList.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfHomeSummaryList.copyWith.fieldName(...)`
class _$HomeSummaryListCWProxyImpl implements _$HomeSummaryListCWProxy {
  const _$HomeSummaryListCWProxyImpl(this._value);

  final HomeSummaryList _value;

  @override
  HomeSummaryList title(String? title) => this(title: title);

  @override
  HomeSummaryList rows(List<HomeRow> rows) => this(rows: rows);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `HomeSummaryList(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// HomeSummaryList(...).copyWith(id: 12, name: "My name")
  /// ````
  HomeSummaryList call({
    Object? title = const $CopyWithPlaceholder(),
    Object? rows = const $CopyWithPlaceholder(),
  }) {
    return HomeSummaryList(
      title: title == const $CopyWithPlaceholder()
          ? _value.title
          // ignore: cast_nullable_to_non_nullable
          : title as String?,
      rows: rows == const $CopyWithPlaceholder()
          ? _value.rows
          // ignore: cast_nullable_to_non_nullable
          : rows as List<HomeRow>,
    );
  }
}

extension $HomeSummaryListCopyWith on HomeSummaryList {
  /// Returns a callable class that can be used as follows: `instanceOfHomeSummaryList.copyWith(...)` or like so:`instanceOfHomeSummaryList.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$HomeSummaryListCWProxy get copyWith => _$HomeSummaryListCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

HomeSummaryList _$HomeSummaryListFromJson(Map<String, dynamic> json) =>
    $checkedCreate('HomeSummaryList', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['rows']);
      final val = HomeSummaryList(
        title: $checkedConvert('title', (v) => v as String?),
        rows: $checkedConvert(
          'rows',
          (v) => (v as List<dynamic>)
              .map((e) => HomeRow.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$HomeSummaryListToJson(HomeSummaryList instance) =>
    <String, dynamic>{
      'title': ?instance.title,
      'rows': instance.rows.map((e) => e.toJson()).toList(),
    };
