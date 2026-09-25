class ExpenseType {
  const ExpenseType._();
  static const income = 'income';
  static const expense = 'expense';
}

class Expense {
  final String id;
  final double amount;
  final String type; // 'income' | 'expense'
  final String category;
  final String note;
  final DateTime createdAt;

  Expense({
    required this.id,
    required this.amount,
    required this.type,
    this.category = '其他',
    this.note = '',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'id': id,
        'amount': amount,
        'type': type,
        'category': category,
        'note': note,
        'createdAt': createdAt.millisecondsSinceEpoch,
      };

  factory Expense.fromMap(Map<dynamic, dynamic> map) => Expense(
        id: map['id'] as String,
        amount: (map['amount'] as num).toDouble(),
        type: map['type'] as String,
        category: map['category'] as String,
        note: map['note'] as String,
        createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
      );
}
