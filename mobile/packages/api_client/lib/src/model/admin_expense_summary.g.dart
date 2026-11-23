// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_expense_summary.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$AdminExpenseSummaryCWProxy {
  AdminExpenseSummary id(String id);

  AdminExpenseSummary reference(String reference);

  AdminExpenseSummary ownerName(String ownerName);

  AdminExpenseSummary amount(int amount);

  AdminExpenseSummary category(ExpenseCategory category);

  AdminExpenseSummary note(String note);

  AdminExpenseSummary spentOn(String spentOn);

  AdminExpenseSummary status(ExpenseStatus status);

  AdminExpenseSummary hasReceipt(bool hasReceipt);

  AdminExpenseSummary createdAt(DateTime createdAt);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `AdminExpenseSummary(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// AdminExpenseSummary(...).copyWith(id: 12, name: "My name")
  /// ````
  AdminExpenseSummary call({
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
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfAdminExpenseSummary.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfAdminExpenseSummary.copyWith.fieldName(...)`
class _$AdminExpenseSummaryCWProxyImpl implements _$AdminExpenseSummaryCWProxy {
  const _$AdminExpenseSummaryCWProxyImpl(this._value);

  final AdminExpenseSummary _value;

  @override
  AdminExpenseSummary id(String id) => this(id: id);

  @override
  AdminExpenseSummary reference(String reference) => this(reference: reference);

  @override
  AdminExpenseSummary ownerName(String ownerName) => this(ownerName: ownerName);

  @override
  AdminExpenseSummary amount(int amount) => this(amount: amount);

  @override
  AdminExpenseSummary category(ExpenseCategory category) =>
      this(category: category);

  @override
  AdminExpenseSummary note(String note) => this(note: note);

  @override
  AdminExpenseSummary spentOn(String spentOn) => this(spentOn: spentOn);

  @override
  AdminExpenseSummary status(ExpenseStatus status) => this(status: status);

  @override
  AdminExpenseSummary hasReceipt(bool hasReceipt) =>
      this(hasReceipt: hasReceipt);

  @override
  AdminExpenseSummary createdAt(DateTime createdAt) =>
      this(createdAt: createdAt);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `AdminExpenseSummary(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// AdminExpenseSummary(...).copyWith(id: 12, name: "My name")
  /// ````
  AdminExpenseSummary call({
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
  }) {
    return AdminExpenseSummary(
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
    );
  }
}

extension $AdminExpenseSummaryCopyWith on AdminExpenseSummary {
  /// Returns a callable class that can be used as follows: `instanceOfAdminExpenseSummary.copyWith(...)` or like so:`instanceOfAdminExpenseSummary.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$AdminExpenseSummaryCWProxy get copyWith =>
      _$AdminExpenseSummaryCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AdminExpenseSummary _$AdminExpenseSummaryFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'AdminExpenseSummary',
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
          ],
        );
        final val = AdminExpenseSummary(
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
        );
        return val;
      },
      fieldKeyMap: const {
        'ownerName': 'owner_name',
        'spentOn': 'spent_on',
        'hasReceipt': 'has_receipt',
        'createdAt': 'created_at',
      },
    );

Map<String, dynamic> _$AdminExpenseSummaryToJson(
  AdminExpenseSummary instance,
) => <String, dynamic>{
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
