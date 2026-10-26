// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'expense_create.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ExpenseCreateCWProxy {
  ExpenseCreate amount(int amount);

  ExpenseCreate category(ExpenseCategory category);

  ExpenseCreate note(String note);

  ExpenseCreate spentOn(String spentOn);

  ExpenseCreate receiptUploadId(String? receiptUploadId);

  ExpenseCreate taskId(String? taskId);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ExpenseCreate(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ExpenseCreate(...).copyWith(id: 12, name: "My name")
  /// ````
  ExpenseCreate call({
    int amount,
    ExpenseCategory category,
    String note,
    String spentOn,
    String? receiptUploadId,
    String? taskId,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfExpenseCreate.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfExpenseCreate.copyWith.fieldName(...)`
class _$ExpenseCreateCWProxyImpl implements _$ExpenseCreateCWProxy {
  const _$ExpenseCreateCWProxyImpl(this._value);

  final ExpenseCreate _value;

  @override
  ExpenseCreate amount(int amount) => this(amount: amount);

  @override
  ExpenseCreate category(ExpenseCategory category) => this(category: category);

  @override
  ExpenseCreate note(String note) => this(note: note);

  @override
  ExpenseCreate spentOn(String spentOn) => this(spentOn: spentOn);

  @override
  ExpenseCreate receiptUploadId(String? receiptUploadId) =>
      this(receiptUploadId: receiptUploadId);

  @override
  ExpenseCreate taskId(String? taskId) => this(taskId: taskId);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ExpenseCreate(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ExpenseCreate(...).copyWith(id: 12, name: "My name")
  /// ````
  ExpenseCreate call({
    Object? amount = const $CopyWithPlaceholder(),
    Object? category = const $CopyWithPlaceholder(),
    Object? note = const $CopyWithPlaceholder(),
    Object? spentOn = const $CopyWithPlaceholder(),
    Object? receiptUploadId = const $CopyWithPlaceholder(),
    Object? taskId = const $CopyWithPlaceholder(),
  }) {
    return ExpenseCreate(
      amount: amount == const $CopyWithPlaceholder()
          ? _value.amount
          // ignore: cast_nullable_to_non_nullable
          : amount as int,
      category: category == const $CopyWithPlaceholder()
          ? _value.category
          // ignore: cast_nullable_to_non_nullable
          : category as ExpenseCategory,
      note: note == const $CopyWithPlaceholder()
          ? _value.note
          // ignore: cast_nullable_to_non_nullable
          : note as String,
      spentOn: spentOn == const $CopyWithPlaceholder()
          ? _value.spentOn
          // ignore: cast_nullable_to_non_nullable
          : spentOn as String,
      receiptUploadId: receiptUploadId == const $CopyWithPlaceholder()
          ? _value.receiptUploadId
          // ignore: cast_nullable_to_non_nullable
          : receiptUploadId as String?,
      taskId: taskId == const $CopyWithPlaceholder()
          ? _value.taskId
          // ignore: cast_nullable_to_non_nullable
          : taskId as String?,
    );
  }
}

extension $ExpenseCreateCopyWith on ExpenseCreate {
  /// Returns a callable class that can be used as follows: `instanceOfExpenseCreate.copyWith(...)` or like so:`instanceOfExpenseCreate.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ExpenseCreateCWProxy get copyWith => _$ExpenseCreateCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ExpenseCreate _$ExpenseCreateFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'ExpenseCreate',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['amount', 'category', 'note', 'spent_on'],
        );
        final val = ExpenseCreate(
          amount: $checkedConvert('amount', (v) => (v as num).toInt()),
          category: $checkedConvert(
            'category',
            (v) => $enumDecode(_$ExpenseCategoryEnumMap, v),
          ),
          note: $checkedConvert('note', (v) => v as String),
          spentOn: $checkedConvert('spent_on', (v) => v as String),
          receiptUploadId: $checkedConvert(
            'receipt_upload_id',
            (v) => v as String?,
          ),
          taskId: $checkedConvert('task_id', (v) => v as String?),
        );
        return val;
      },
      fieldKeyMap: const {
        'spentOn': 'spent_on',
        'receiptUploadId': 'receipt_upload_id',
        'taskId': 'task_id',
      },
    );

Map<String, dynamic> _$ExpenseCreateToJson(ExpenseCreate instance) =>
    <String, dynamic>{
      'amount': instance.amount,
      'category': _$ExpenseCategoryEnumMap[instance.category]!,
      'note': instance.note,
      'spent_on': instance.spentOn,
      'receipt_upload_id': ?instance.receiptUploadId,
      'task_id': ?instance.taskId,
    };

const _$ExpenseCategoryEnumMap = {
  ExpenseCategory.fuel: 'fuel',
  ExpenseCategory.material: 'material',
  ExpenseCategory.labour: 'labour',
  ExpenseCategory.other: 'other',
};
