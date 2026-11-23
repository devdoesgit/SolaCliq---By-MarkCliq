// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lead_summary.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$LeadSummaryCWProxy {
  LeadSummary id(String id);

  LeadSummary name(String name);

  LeadSummary phone(String phone);

  LeadSummary city(String? city);

  LeadSummary source_(String source_);

  LeadSummary status(LeadStatus status);

  LeadSummary agentId(String? agentId);

  LeadSummary agentName(String? agentName);

  LeadSummary receivedAt(DateTime receivedAt);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `LeadSummary(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// LeadSummary(...).copyWith(id: 12, name: "My name")
  /// ````
  LeadSummary call({
    String id,
    String name,
    String phone,
    String? city,
    String source_,
    LeadStatus status,
    String? agentId,
    String? agentName,
    DateTime receivedAt,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfLeadSummary.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfLeadSummary.copyWith.fieldName(...)`
class _$LeadSummaryCWProxyImpl implements _$LeadSummaryCWProxy {
  const _$LeadSummaryCWProxyImpl(this._value);

  final LeadSummary _value;

  @override
  LeadSummary id(String id) => this(id: id);

  @override
  LeadSummary name(String name) => this(name: name);

  @override
  LeadSummary phone(String phone) => this(phone: phone);

  @override
  LeadSummary city(String? city) => this(city: city);

  @override
  LeadSummary source_(String source_) => this(source_: source_);

  @override
  LeadSummary status(LeadStatus status) => this(status: status);

  @override
  LeadSummary agentId(String? agentId) => this(agentId: agentId);

  @override
  LeadSummary agentName(String? agentName) => this(agentName: agentName);

  @override
  LeadSummary receivedAt(DateTime receivedAt) => this(receivedAt: receivedAt);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `LeadSummary(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// LeadSummary(...).copyWith(id: 12, name: "My name")
  /// ````
  LeadSummary call({
    Object? id = const $CopyWithPlaceholder(),
    Object? name = const $CopyWithPlaceholder(),
    Object? phone = const $CopyWithPlaceholder(),
    Object? city = const $CopyWithPlaceholder(),
    Object? source_ = const $CopyWithPlaceholder(),
    Object? status = const $CopyWithPlaceholder(),
    Object? agentId = const $CopyWithPlaceholder(),
    Object? agentName = const $CopyWithPlaceholder(),
    Object? receivedAt = const $CopyWithPlaceholder(),
  }) {
    return LeadSummary(
      id: id == const $CopyWithPlaceholder()
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      name: name == const $CopyWithPlaceholder()
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String,
      phone: phone == const $CopyWithPlaceholder()
          ? _value.phone
          // ignore: cast_nullable_to_non_nullable
          : phone as String,
      city: city == const $CopyWithPlaceholder()
          ? _value.city
          // ignore: cast_nullable_to_non_nullable
          : city as String?,
      source_: source_ == const $CopyWithPlaceholder()
          ? _value.source_
          // ignore: cast_nullable_to_non_nullable
          : source_ as String,
      status: status == const $CopyWithPlaceholder()
          ? _value.status
          // ignore: cast_nullable_to_non_nullable
          : status as LeadStatus,
      agentId: agentId == const $CopyWithPlaceholder()
          ? _value.agentId
          // ignore: cast_nullable_to_non_nullable
          : agentId as String?,
      agentName: agentName == const $CopyWithPlaceholder()
          ? _value.agentName
          // ignore: cast_nullable_to_non_nullable
          : agentName as String?,
      receivedAt: receivedAt == const $CopyWithPlaceholder()
          ? _value.receivedAt
          // ignore: cast_nullable_to_non_nullable
          : receivedAt as DateTime,
    );
  }
}

extension $LeadSummaryCopyWith on LeadSummary {
  /// Returns a callable class that can be used as follows: `instanceOfLeadSummary.copyWith(...)` or like so:`instanceOfLeadSummary.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$LeadSummaryCWProxy get copyWith => _$LeadSummaryCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LeadSummary _$LeadSummaryFromJson(Map<String, dynamic> json) => $checkedCreate(
  'LeadSummary',
  json,
  ($checkedConvert) {
    $checkKeys(
      json,
      requiredKeys: const [
        'id',
        'name',
        'phone',
        'source',
        'status',
        'received_at',
      ],
    );
    final val = LeadSummary(
      id: $checkedConvert('id', (v) => v as String),
      name: $checkedConvert('name', (v) => v as String),
      phone: $checkedConvert('phone', (v) => v as String),
      city: $checkedConvert('city', (v) => v as String?),
      source_: $checkedConvert('source', (v) => v as String),
      status: $checkedConvert(
        'status',
        (v) => $enumDecode(_$LeadStatusEnumMap, v),
      ),
      agentId: $checkedConvert('agent_id', (v) => v as String?),
      agentName: $checkedConvert('agent_name', (v) => v as String?),
      receivedAt: $checkedConvert(
        'received_at',
        (v) => DateTime.parse(v as String),
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'source_': 'source',
    'agentId': 'agent_id',
    'agentName': 'agent_name',
    'receivedAt': 'received_at',
  },
);

Map<String, dynamic> _$LeadSummaryToJson(LeadSummary instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'phone': instance.phone,
      'city': ?instance.city,
      'source': instance.source_,
      'status': _$LeadStatusEnumMap[instance.status]!,
      'agent_id': ?instance.agentId,
      'agent_name': ?instance.agentName,
      'received_at': instance.receivedAt.toIso8601String(),
    };

const _$LeadStatusEnumMap = {
  LeadStatus.new_: 'new',
  LeadStatus.contacted: 'contacted',
  LeadStatus.won: 'won',
  LeadStatus.lost: 'lost',
};
