// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'set_task_checklist_item_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$SetTaskChecklistItemRequestCWProxy {
  SetTaskChecklistItemRequest done(bool done);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `SetTaskChecklistItemRequest(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// SetTaskChecklistItemRequest(...).copyWith(id: 12, name: "My name")
  /// ````
  SetTaskChecklistItemRequest call({bool done});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfSetTaskChecklistItemRequest.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfSetTaskChecklistItemRequest.copyWith.fieldName(...)`
class _$SetTaskChecklistItemRequestCWProxyImpl
    implements _$SetTaskChecklistItemRequestCWProxy {
  const _$SetTaskChecklistItemRequestCWProxyImpl(this._value);

  final SetTaskChecklistItemRequest _value;

  @override
  SetTaskChecklistItemRequest done(bool done) => this(done: done);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `SetTaskChecklistItemRequest(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// SetTaskChecklistItemRequest(...).copyWith(id: 12, name: "My name")
  /// ````
  SetTaskChecklistItemRequest call({
    Object? done = const $CopyWithPlaceholder(),
  }) {
    return SetTaskChecklistItemRequest(
      done: done == const $CopyWithPlaceholder()
          ? _value.done
          // ignore: cast_nullable_to_non_nullable
          : done as bool,
    );
  }
}

extension $SetTaskChecklistItemRequestCopyWith on SetTaskChecklistItemRequest {
  /// Returns a callable class that can be used as follows: `instanceOfSetTaskChecklistItemRequest.copyWith(...)` or like so:`instanceOfSetTaskChecklistItemRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$SetTaskChecklistItemRequestCWProxy get copyWith =>
      _$SetTaskChecklistItemRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SetTaskChecklistItemRequest _$SetTaskChecklistItemRequestFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('SetTaskChecklistItemRequest', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['done']);
  final val = SetTaskChecklistItemRequest(
    done: $checkedConvert('done', (v) => v as bool),
  );
  return val;
});

Map<String, dynamic> _$SetTaskChecklistItemRequestToJson(
  SetTaskChecklistItemRequest instance,
) => <String, dynamic>{'done': instance.done};
