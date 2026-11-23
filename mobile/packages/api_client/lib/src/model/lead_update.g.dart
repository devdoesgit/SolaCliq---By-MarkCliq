// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lead_update.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$LeadUpdateCWProxy {
  LeadUpdate status(LeadStatus? status);

  LeadUpdate note(String? note);

  LeadUpdate agentId(String? agentId);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `LeadUpdate(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// LeadUpdate(...).copyWith(id: 12, name: "My name")
  /// ````
  LeadUpdate call({LeadStatus? status, String? note, String? agentId});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfLeadUpdate.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfLeadUpdate.copyWith.fieldName(...)`
class _$LeadUpdateCWProxyImpl implements _$LeadUpdateCWProxy {
  const _$LeadUpdateCWProxyImpl(this._value);

  final LeadUpdate _value;

  @override
  LeadUpdate status(LeadStatus? status) => this(status: status);

  @override
  LeadUpdate note(String? note) => this(note: note);

  @override
  LeadUpdate agentId(String? agentId) => this(agentId: agentId);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `LeadUpdate(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// LeadUpdate(...).copyWith(id: 12, name: "My name")
  /// ````
  LeadUpdate call({
    Object? status = const $CopyWithPlaceholder(),
    Object? note = const $CopyWithPlaceholder(),
    Object? agentId = const $CopyWithPlaceholder(),
  }) {
    return LeadUpdate(
      status: status == const $CopyWithPlaceholder()
          ? _value.status
          // ignore: cast_nullable_to_non_nullable
          : status as LeadStatus?,
      note: note == const $CopyWithPlaceholder()
          ? _value.note
          // ignore: cast_nullable_to_non_nullable
          : note as String?,
      agentId: agentId == const $CopyWithPlaceholder()
          ? _value.agentId
          // ignore: cast_nullable_to_non_nullable
          : agentId as String?,
    );
  }
}

extension $LeadUpdateCopyWith on LeadUpdate {
  /// Returns a callable class that can be used as follows: `instanceOfLeadUpdate.copyWith(...)` or like so:`instanceOfLeadUpdate.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$LeadUpdateCWProxy get copyWith => _$LeadUpdateCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LeadUpdate _$LeadUpdateFromJson(Map<String, dynamic> json) =>
    $checkedCreate('LeadUpdate', json, ($checkedConvert) {
      final val = LeadUpdate(
        status: $checkedConvert(
          'status',
          (v) => $enumDecodeNullable(_$LeadStatusEnumMap, v),
        ),
        note: $checkedConvert('note', (v) => v as String?),
        agentId: $checkedConvert('agent_id', (v) => v as String?),
      );
      return val;
    }, fieldKeyMap: const {'agentId': 'agent_id'});

Map<String, dynamic> _$LeadUpdateToJson(LeadUpdate instance) =>
    <String, dynamic>{
      'status': ?_$LeadStatusEnumMap[instance.status],
      'note': ?instance.note,
      'agent_id': ?instance.agentId,
    };

const _$LeadStatusEnumMap = {
  LeadStatus.new_: 'new',
  LeadStatus.contacted: 'contacted',
  LeadStatus.won: 'won',
  LeadStatus.lost: 'lost',
};
