// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'install_next_visit.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$InstallNextVisitCWProxy {
  InstallNextVisit title(String title);

  InstallNextVisit startsAt(DateTime startsAt);

  InstallNextVisit endsAt(DateTime? endsAt);

  InstallNextVisit person(InstallNextVisitPerson person);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `InstallNextVisit(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// InstallNextVisit(...).copyWith(id: 12, name: "My name")
  /// ````
  InstallNextVisit call({
    String title,
    DateTime startsAt,
    DateTime? endsAt,
    InstallNextVisitPerson person,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfInstallNextVisit.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfInstallNextVisit.copyWith.fieldName(...)`
class _$InstallNextVisitCWProxyImpl implements _$InstallNextVisitCWProxy {
  const _$InstallNextVisitCWProxyImpl(this._value);

  final InstallNextVisit _value;

  @override
  InstallNextVisit title(String title) => this(title: title);

  @override
  InstallNextVisit startsAt(DateTime startsAt) => this(startsAt: startsAt);

  @override
  InstallNextVisit endsAt(DateTime? endsAt) => this(endsAt: endsAt);

  @override
  InstallNextVisit person(InstallNextVisitPerson person) =>
      this(person: person);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `InstallNextVisit(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// InstallNextVisit(...).copyWith(id: 12, name: "My name")
  /// ````
  InstallNextVisit call({
    Object? title = const $CopyWithPlaceholder(),
    Object? startsAt = const $CopyWithPlaceholder(),
    Object? endsAt = const $CopyWithPlaceholder(),
    Object? person = const $CopyWithPlaceholder(),
  }) {
    return InstallNextVisit(
      title: title == const $CopyWithPlaceholder()
          ? _value.title
          // ignore: cast_nullable_to_non_nullable
          : title as String,
      startsAt: startsAt == const $CopyWithPlaceholder()
          ? _value.startsAt
          // ignore: cast_nullable_to_non_nullable
          : startsAt as DateTime,
      endsAt: endsAt == const $CopyWithPlaceholder()
          ? _value.endsAt
          // ignore: cast_nullable_to_non_nullable
          : endsAt as DateTime?,
      person: person == const $CopyWithPlaceholder()
          ? _value.person
          // ignore: cast_nullable_to_non_nullable
          : person as InstallNextVisitPerson,
    );
  }
}

extension $InstallNextVisitCopyWith on InstallNextVisit {
  /// Returns a callable class that can be used as follows: `instanceOfInstallNextVisit.copyWith(...)` or like so:`instanceOfInstallNextVisit.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$InstallNextVisitCWProxy get copyWith => _$InstallNextVisitCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

InstallNextVisit _$InstallNextVisitFromJson(Map<String, dynamic> json) =>
    $checkedCreate('InstallNextVisit', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['title', 'starts_at', 'person']);
      final val = InstallNextVisit(
        title: $checkedConvert('title', (v) => v as String),
        startsAt: $checkedConvert(
          'starts_at',
          (v) => DateTime.parse(v as String),
        ),
        endsAt: $checkedConvert(
          'ends_at',
          (v) => v == null ? null : DateTime.parse(v as String),
        ),
        person: $checkedConvert(
          'person',
          (v) => InstallNextVisitPerson.fromJson(v as Map<String, dynamic>),
        ),
      );
      return val;
    }, fieldKeyMap: const {'startsAt': 'starts_at', 'endsAt': 'ends_at'});

Map<String, dynamic> _$InstallNextVisitToJson(InstallNextVisit instance) =>
    <String, dynamic>{
      'title': instance.title,
      'starts_at': instance.startsAt.toIso8601String(),
      'ends_at': ?instance.endsAt?.toIso8601String(),
      'person': instance.person.toJson(),
    };
