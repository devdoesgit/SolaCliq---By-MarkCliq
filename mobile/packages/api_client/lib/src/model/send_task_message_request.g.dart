// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'send_task_message_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$SendTaskMessageRequestCWProxy {
  SendTaskMessageRequest text(String text);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `SendTaskMessageRequest(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// SendTaskMessageRequest(...).copyWith(id: 12, name: "My name")
  /// ````
  SendTaskMessageRequest call({String text});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfSendTaskMessageRequest.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfSendTaskMessageRequest.copyWith.fieldName(...)`
class _$SendTaskMessageRequestCWProxyImpl
    implements _$SendTaskMessageRequestCWProxy {
  const _$SendTaskMessageRequestCWProxyImpl(this._value);

  final SendTaskMessageRequest _value;

  @override
  SendTaskMessageRequest text(String text) => this(text: text);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `SendTaskMessageRequest(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// SendTaskMessageRequest(...).copyWith(id: 12, name: "My name")
  /// ````
  SendTaskMessageRequest call({Object? text = const $CopyWithPlaceholder()}) {
    return SendTaskMessageRequest(
      text: text == const $CopyWithPlaceholder()
          ? _value.text
          // ignore: cast_nullable_to_non_nullable
          : text as String,
    );
  }
}

extension $SendTaskMessageRequestCopyWith on SendTaskMessageRequest {
  /// Returns a callable class that can be used as follows: `instanceOfSendTaskMessageRequest.copyWith(...)` or like so:`instanceOfSendTaskMessageRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$SendTaskMessageRequestCWProxy get copyWith =>
      _$SendTaskMessageRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SendTaskMessageRequest _$SendTaskMessageRequestFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('SendTaskMessageRequest', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['text']);
  final val = SendTaskMessageRequest(
    text: $checkedConvert('text', (v) => v as String),
  );
  return val;
});

Map<String, dynamic> _$SendTaskMessageRequestToJson(
  SendTaskMessageRequest instance,
) => <String, dynamic>{'text': instance.text};
