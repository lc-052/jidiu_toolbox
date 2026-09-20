import 'package:hive_flutter/hive_flutter.dart';
import '../models/expense.dart';

class ExpenseService {
  late final Box _box;

  ExpenseService() {
    _box = Hive.box('expenses');
  }

  List<Expense> getAll({int? year, int? month}) {
    var items =
        _box.values.cast<Map<dynamic, dynamic>>().map(Expense.fromMap).toList();
    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    if (year != null) items.removeWhere((e) => e.createdAt.year != year);
    if (month != null) items.removeWhere((e) => e.createdAt.month != month);

    return items;
  }

  Future<void> add(Expense expense) async {
    await _box.put(expense.id, expense.toMap());
  }

  Future<void> delete(String id) async {
    await _box.delete(id);
  }

  ({double income, double expense, double balance}) statsForMonth(
      int year, int month) {
    final items = getAll(year: year, month: month);
    double income = 0, expense = 0;
    for (final e in items) {
      if (e.type == ExpenseType.income) income += e.amount;
      else expense += e.amount;
    }
    return (income: income, expense: expense, balance: income - expense);
  }
}
