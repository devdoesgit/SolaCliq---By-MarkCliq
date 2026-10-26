// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'expense.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ExpenseCWProxy {
  Expense id(String id);

  Expense reference(String reference);

  Expense amount(int amount);

  Expense category(ExpenseCategory category);

  Expense note(String note);

  Expense spentOn(String spentOn);

  Expense status(ExpenseStatus status);

  Expense hasReceipt(bool hasReceipt);

  Expense adminNote(String? adminNote);

  Expense adminName(String? adminName);

  Expense task(TaskRef? task);

  Expense receiptUrl(String? receiptUrl);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `Expense(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// Expense(...).copyWith(id: 12, name: "My name")
  /// ````
  Expense call({
    String id,
    String reference,
    int amount,
    ExpenseCategory category,
    String note,
    String spentOn,
    ExpenseStatus status,
    bool hasReceipt,
    String? adminNote,
    String? adminName,
    TaskRef? task,
    String? receiptUrl,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfExpense.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfExpense.copyWith.fieldName(...)`
class _$ExpenseCWProxyImpl implements _$ExpenseCWProxy {
  const _$ExpenseCWProxyImpl(this._value);

  final Expense _value;

  @override
  Expense id(String id) => this(id: id);

  @override
  Expense reference(String reference) => this(reference: reference);

  @override
  Expense amount(int amount) => this(amount: amount);

  @override
  Expense category(ExpenseCategory category) => this(category: category);

  @override
  Expense note(String note) => this(note: note);

  @override
  Expense spentOn(String spentOn) => this(spentOn: spentOn);

  @override
  Expense status(ExpenseStatus status) => this(status: status);

  @override
  Expense hasReceipt(bool hasReceipt) => this(hasReceipt: hasReceipt);

  @override
  Expense adminNote(String? adminNote) => this(adminNote: adminNote);

  @override
  Expense adminName(String? adminName) => this(adminName: adminName);

  @override
  Expense task(TaskRef? task) => this(task: task);

  @override
  Expense receiptUrl(String? receiptUrl) => this(receiptUrl: receiptUrl);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `Expense(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// Expense(...).copyWith(id: 12, name: "My name")
  /// ````
  Expense call({
    Object? id = const $CopyWithPlaceholder(),
    Object? reference = const $CopyWithPlaceholder(),
    Object? amount = const $CopyWithPlaceholder(),
    Object? category = const $CopyWithPlaceholder(),
    Object? note = const $CopyWithPlaceholder(),
    Object? spentOn = const $CopyWithPlaceholder(),
    Object? status = const $CopyWithPlaceholder(),
    Object? hasReceipt = const $CopyWithPlaceholder(),
    Object? adminNote = const $CopyWithPlaceholder(),
    Object? adminName = const $CopyWithPlaceholder(),
    Object? task = const $CopyWithPlaceholder(),
    Object? receiptUrl = const $CopyWithPlaceholder(),
  }) {
    return Expense(
      id: id == const $CopyWithPlaceholder()
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      reference: reference == const $CopyWithPlaceholder()
          ? _value.reference
          // ignore: cast_nullable_to_non_nullable
          : reference as String,
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
      status: status == const $CopyWithPlaceholder()
          ? _value.status
          // ignore: cast_nullable_to_non_nullable
          : status as ExpenseStatus,
      hasReceipt: hasReceipt == const $CopyWithPlaceholder()
          ? _value.hasReceipt
          // ignore: cast_nullable_to_non_nullable
          : hasReceipt as bool,
      adminNote: adminNote == const $CopyWithPlaceholder()
          ? _value.adminNote
          // ignore: cast_nullable_to_non_nullable
          : adminNote as String?,
      adminName: adminName == const $CopyWithPlaceholder()
          ? _value.adminName
          // ignore: cast_nullable_to_non_nullable
          : adminName as String?,
      task: task == const $CopyWithPlaceholder()
          ? _value.task
          // ignore: cast_nullable_to_non_nullable
          : task as TaskRef?,
      receiptUrl: receiptUrl == const $CopyWithPlaceholder()
          ? _value.receiptUrl
          // ignore: cast_nullable_to_non_nullable
          : receiptUrl as String?,
    );
  }
}

extension $ExpenseCopyWith on Expense {
  /// Returns a callable class that can be used as follows: `instanceOfExpense.copyWith(...)` or like so:`instanceOfExpense.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ExpenseCWProxy get copyWith => _$ExpenseCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Expense _$ExpenseFromJson(Map<String, dynamic> json) => $checkedCreate(
  'Expense',
  json,
  ($checkedConvert) {
    $checkKeys(
      json,
      requiredKeys: const [
        'id',
        'reference',
        'amount',
        'category',
        'note',
        'spent_on',
        'status',
        'has_receipt',
      ],
    );
    final val = Expense(
      id: $checkedConvert('id', (v) => v as String),
      reference: $checkedConvert('reference', (v) => v as String),
      amount: $checkedConvert('amount', (v) => (v as num).toInt()),
      category: $checkedConvert(
        'category',
        (v) => $enumDecode(_$ExpenseCategoryEnumMap, v),
      ),
      note: $checkedConvert('note', (v) => v as String),
      spentOn: $checkedConvert('spent_on', (v) => v as String),
      status: $checkedConvert(
        'status',
        (v) => $enumDecode(_$ExpenseStatusEnumMap, v),
      ),
      hasReceipt: $checkedConvert('has_receipt', (v) => v as bool),
      adminNote: $checkedConvert('admin_note', (v) => v as String?),
      adminName: $checkedConvert('admin_name', (v) => v as String?),
      task: $checkedConvert(
        'task',
        (v) => v == null ? null : TaskRef.fromJson(v as Map<String, dynamic>),
      ),
      receiptUrl: $checkedConvert('receipt_url', (v) => v as String?),
    );
    return val;
  },
  fieldKeyMap: const {
    'spentOn': 'spent_on',
    'hasReceipt': 'has_receipt',
    'adminNote': 'admin_note',
    'adminName': 'admin_name',
    'receiptUrl': 'receipt_url',
  },
);

Map<String, dynamic> _$ExpenseToJson(Expense instance) => <String, dynamic>{
  'id': instance.id,
  'reference': instance.reference,
  'amount': instance.amount,
  'category': _$ExpenseCategoryEnumMap[instance.category]!,
  'note': instance.note,
  'spent_on': instance.spentOn,
  'status': _$ExpenseStatusEnumMap[instance.status]!,
  'has_receipt': instance.hasReceipt,
  'admin_note': ?instance.adminNote,
  'admin_name': ?instance.adminName,
  'task': ?instance.task?.toJson(),
  'receipt_url': ?instance.receiptUrl,
};

const _$ExpenseCategoryEnumMap = {
  ExpenseCategory.fuel: 'fuel',
  ExpenseCategory.material: 'material',
  ExpenseCategory.labour: 'labour',
  ExpenseCategory.other: 'other',
};

const _$ExpenseStatusEnumMap = {
  ExpenseStatus.inReview: 'in_review',
  ExpenseStatus.approved: 'approved',
  ExpenseStatus.needsFix: 'needs_fix',
  ExpenseStatus.paid: 'paid',
};
