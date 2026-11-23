// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_expense.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$AdminExpenseCWProxy {
  AdminExpense id(String id);

  AdminExpense reference(String reference);

  AdminExpense ownerName(String ownerName);

  AdminExpense amount(int amount);

  AdminExpense category(ExpenseCategory category);

  AdminExpense note(String note);

  AdminExpense spentOn(String spentOn);

  AdminExpense status(ExpenseStatus status);

  AdminExpense hasReceipt(bool hasReceipt);

  AdminExpense createdAt(DateTime createdAt);

  AdminExpense statusAt(DateTime statusAt);

  AdminExpense receipt(AdminFile? receipt);

  AdminExpense adminNote(String? adminNote);

  AdminExpense fixNote(String? fixNote);

  AdminExpense adminName(String? adminName);

  AdminExpense task(TaskRef? task);

  AdminExpense payoutLast4(String? payoutLast4);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `AdminExpense(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// AdminExpense(...).copyWith(id: 12, name: "My name")
  /// ````
  AdminExpense call({
    String id,
    String reference,
    String ownerName,
    int amount,
    ExpenseCategory category,
    String note,
    String spentOn,
    ExpenseStatus status,
    bool hasReceipt,
    DateTime createdAt,
    DateTime statusAt,
    AdminFile? receipt,
    String? adminNote,
    String? fixNote,
    String? adminName,
    TaskRef? task,
    String? payoutLast4,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfAdminExpense.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfAdminExpense.copyWith.fieldName(...)`
class _$AdminExpenseCWProxyImpl implements _$AdminExpenseCWProxy {
  const _$AdminExpenseCWProxyImpl(this._value);

  final AdminExpense _value;

  @override
  AdminExpense id(String id) => this(id: id);

  @override
  AdminExpense reference(String reference) => this(reference: reference);

  @override
  AdminExpense ownerName(String ownerName) => this(ownerName: ownerName);

  @override
  AdminExpense amount(int amount) => this(amount: amount);

  @override
  AdminExpense category(ExpenseCategory category) => this(category: category);

  @override
  AdminExpense note(String note) => this(note: note);

  @override
  AdminExpense spentOn(String spentOn) => this(spentOn: spentOn);

  @override
  AdminExpense status(ExpenseStatus status) => this(status: status);

  @override
  AdminExpense hasReceipt(bool hasReceipt) => this(hasReceipt: hasReceipt);

  @override
  AdminExpense createdAt(DateTime createdAt) => this(createdAt: createdAt);

  @override
  AdminExpense statusAt(DateTime statusAt) => this(statusAt: statusAt);

  @override
  AdminExpense receipt(AdminFile? receipt) => this(receipt: receipt);

  @override
  AdminExpense adminNote(String? adminNote) => this(adminNote: adminNote);

  @override
  AdminExpense fixNote(String? fixNote) => this(fixNote: fixNote);

  @override
  AdminExpense adminName(String? adminName) => this(adminName: adminName);

  @override
  AdminExpense task(TaskRef? task) => this(task: task);

  @override
  AdminExpense payoutLast4(String? payoutLast4) =>
      this(payoutLast4: payoutLast4);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `AdminExpense(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// AdminExpense(...).copyWith(id: 12, name: "My name")
  /// ````
  AdminExpense call({
    Object? id = const $CopyWithPlaceholder(),
    Object? reference = const $CopyWithPlaceholder(),
    Object? ownerName = const $CopyWithPlaceholder(),
    Object? amount = const $CopyWithPlaceholder(),
    Object? category = const $CopyWithPlaceholder(),
    Object? note = const $CopyWithPlaceholder(),
    Object? spentOn = const $CopyWithPlaceholder(),
    Object? status = const $CopyWithPlaceholder(),
    Object? hasReceipt = const $CopyWithPlaceholder(),
    Object? createdAt = const $CopyWithPlaceholder(),
    Object? statusAt = const $CopyWithPlaceholder(),
    Object? receipt = const $CopyWithPlaceholder(),
    Object? adminNote = const $CopyWithPlaceholder(),
    Object? fixNote = const $CopyWithPlaceholder(),
    Object? adminName = const $CopyWithPlaceholder(),
    Object? task = const $CopyWithPlaceholder(),
    Object? payoutLast4 = const $CopyWithPlaceholder(),
  }) {
    return AdminExpense(
      id: id == const $CopyWithPlaceholder()
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      reference: reference == const $CopyWithPlaceholder()
          ? _value.reference
          // ignore: cast_nullable_to_non_nullable
          : reference as String,
      ownerName: ownerName == const $CopyWithPlaceholder()
          ? _value.ownerName
          // ignore: cast_nullable_to_non_nullable
          : ownerName as String,
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
      createdAt: createdAt == const $CopyWithPlaceholder()
          ? _value.createdAt
          // ignore: cast_nullable_to_non_nullable
          : createdAt as DateTime,
      statusAt: statusAt == const $CopyWithPlaceholder()
          ? _value.statusAt
          // ignore: cast_nullable_to_non_nullable
          : statusAt as DateTime,
      receipt: receipt == const $CopyWithPlaceholder()
          ? _value.receipt
          // ignore: cast_nullable_to_non_nullable
          : receipt as AdminFile?,
      adminNote: adminNote == const $CopyWithPlaceholder()
          ? _value.adminNote
          // ignore: cast_nullable_to_non_nullable
          : adminNote as String?,
      fixNote: fixNote == const $CopyWithPlaceholder()
          ? _value.fixNote
          // ignore: cast_nullable_to_non_nullable
          : fixNote as String?,
      adminName: adminName == const $CopyWithPlaceholder()
          ? _value.adminName
          // ignore: cast_nullable_to_non_nullable
          : adminName as String?,
      task: task == const $CopyWithPlaceholder()
          ? _value.task
          // ignore: cast_nullable_to_non_nullable
          : task as TaskRef?,
      payoutLast4: payoutLast4 == const $CopyWithPlaceholder()
          ? _value.payoutLast4
          // ignore: cast_nullable_to_non_nullable
          : payoutLast4 as String?,
    );
  }
}

extension $AdminExpenseCopyWith on AdminExpense {
  /// Returns a callable class that can be used as follows: `instanceOfAdminExpense.copyWith(...)` or like so:`instanceOfAdminExpense.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$AdminExpenseCWProxy get copyWith => _$AdminExpenseCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AdminExpense _$AdminExpenseFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'AdminExpense',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'id',
            'reference',
            'owner_name',
            'amount',
            'category',
            'note',
            'spent_on',
            'status',
            'has_receipt',
            'created_at',
            'status_at',
          ],
        );
        final val = AdminExpense(
          id: $checkedConvert('id', (v) => v as String),
          reference: $checkedConvert('reference', (v) => v as String),
          ownerName: $checkedConvert('owner_name', (v) => v as String),
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
          createdAt: $checkedConvert(
            'created_at',
            (v) => DateTime.parse(v as String),
          ),
          statusAt: $checkedConvert(
            'status_at',
            (v) => DateTime.parse(v as String),
          ),
          receipt: $checkedConvert(
            'receipt',
            (v) => v == null
                ? null
                : AdminFile.fromJson(v as Map<String, dynamic>),
          ),
          adminNote: $checkedConvert('admin_note', (v) => v as String?),
          fixNote: $checkedConvert('fix_note', (v) => v as String?),
          adminName: $checkedConvert('admin_name', (v) => v as String?),
          task: $checkedConvert(
            'task',
            (v) =>
                v == null ? null : TaskRef.fromJson(v as Map<String, dynamic>),
          ),
          payoutLast4: $checkedConvert('payout_last4', (v) => v as String?),
        );
        return val;
      },
      fieldKeyMap: const {
        'ownerName': 'owner_name',
        'spentOn': 'spent_on',
        'hasReceipt': 'has_receipt',
        'createdAt': 'created_at',
        'statusAt': 'status_at',
        'adminNote': 'admin_note',
        'fixNote': 'fix_note',
        'adminName': 'admin_name',
        'payoutLast4': 'payout_last4',
      },
    );

Map<String, dynamic> _$AdminExpenseToJson(AdminExpense instance) =>
    <String, dynamic>{
      'id': instance.id,
      'reference': instance.reference,
      'owner_name': instance.ownerName,
      'amount': instance.amount,
      'category': _$ExpenseCategoryEnumMap[instance.category]!,
      'note': instance.note,
      'spent_on': instance.spentOn,
      'status': _$ExpenseStatusEnumMap[instance.status]!,
      'has_receipt': instance.hasReceipt,
      'created_at': instance.createdAt.toIso8601String(),
      'status_at': instance.statusAt.toIso8601String(),
      'receipt': ?instance.receipt?.toJson(),
      'admin_note': ?instance.adminNote,
      'fix_note': ?instance.fixNote,
      'admin_name': ?instance.adminName,
      'task': ?instance.task?.toJson(),
      'payout_last4': ?instance.payoutLast4,
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
  ExpenseStatus.rejected: 'rejected',
};
