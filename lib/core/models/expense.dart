import 'enums.dart';

class Expense {
  const Expense({
    required this.id,
    required this.lotId,
    required this.expenseType,
    required this.amountMyr,
    required this.expenseDate,
    this.notes,
    required this.createdAt,
  });

  final String id;
  final String lotId;
  final ExpenseType expenseType;
  final double amountMyr;
  final DateTime expenseDate;
  final String? notes;
  final DateTime createdAt;

  factory Expense.fromJson(Map<String, dynamic> json) => Expense(
        id: json['id'] as String,
        lotId: json['lot_id'] as String,
        expenseType: ExpenseType.fromString(json['expense_type'] as String),
        amountMyr: (json['amount_myr'] as num).toDouble(),
        expenseDate: DateTime.parse(json['expense_date'] as String),
        notes: json['notes'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  Map<String, dynamic> toInsertJson() => {
        'lot_id': lotId,
        'expense_type': expenseType.name,
        'amount_myr': amountMyr,
        'expense_date': expenseDate.toIso8601String().split('T').first,
        'notes': notes,
      };
}
