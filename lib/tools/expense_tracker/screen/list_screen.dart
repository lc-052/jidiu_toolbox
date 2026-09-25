import 'package:flutter/material.dart';
import 'entry_screen.dart';
import '../../../shared/widgets/common_app_bar.dart';
import '../models/expense.dart';
import '../services/expense_service.dart';

class ExpenseListScreen extends StatefulWidget {
  const ExpenseListScreen({super.key});
  @override
  State<ExpenseListScreen> createState() => _ExpenseListScreenState();
}

class _ExpenseListScreenState extends State<ExpenseListScreen> {
  late final _service = ExpenseService();
  List<Expense> _items = [];
  ({double income, double expense, double balance})
      _stats = (income: 0, expense: 0, balance: 0);

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    setState(() {
      _items = _service.getAll();
      final now = DateTime.now();
      _stats = _service.statsForMonth(now.year, now.month);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(title: '寄丢记账'),
      body: SafeArea(
        child: Column(
          children: [
            // Summary card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _statRow('收入',
                        '+¥${_stats.income.toStringAsFixed(2)}', Colors.green),
                    _statRow('支出',
                        '-¥${_stats.expense.toStringAsFixed(2)}', Colors.red),
                    _statRow(
                        '结余',
                        '¥${_stats.balance.toStringAsFixed(2)}',
                        Theme.of(context).colorScheme.primary),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _items.isEmpty
                  ? const Center(
                      child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.receipt_long,
                                size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                                '暂无记录',
                                style: TextStyle(color: Colors.grey))
                          ]))
                  : ListView.builder(
                      itemCount: _items.length,
                      itemBuilder: (context, index) {
                        final item = _items[index];
                        return Dismissible(
                          key: ValueKey(item.id),
                          direction: DismissDirection.endToStart,
                          background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 16),
                              color: Colors.red.shade100,
                              child: const Icon(Icons.delete,
                                  color: Colors.red)),
                          onDismissed: (_) {
                            _service.delete(item.id);
                            _refresh();
                          },
                          child: ListTile(
                            leading: CircleAvatar(
                                backgroundColor: item.type ==
                                        ExpenseType.income
                                    ? Colors.green.shade100
                                    : Colors.red.shade100,
                                child: Icon(
                                    item.type == ExpenseType.income
                                        ? Icons.arrow_downward
                                        : Icons.arrow_upward,
                                    color: item.type == ExpenseType.income
                                        ? Colors.green
                                        : Colors.red)),
                            title: Text(
                                '${item.category}${item.note.isNotEmpty ? ' - ${item.note}' : ''}'),
                            subtitle: Text(
                                '${item.createdAt.month}/${item.createdAt.day} ${item.createdAt.hour}:${item.createdAt.minute.toString().padLeft(2, '0')}'),
                            trailing: Text(
                              '${item.type == ExpenseType.income ? '+' : '-'}¥${item.amount.toStringAsFixed(2)}',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                      color: item.type == ExpenseType.income
                                          ? Colors.green
                                          : Colors.red,
                                      fontWeight: FontWeight.bold),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _goToEntry(),
          icon: const Icon(Icons.add),
          label: const Text('记一笔')),
    );
  }

  Future<void> _goToEntry() async {
    await Navigator.push(
        context, MaterialPageRoute(builder: (_) => const EntryScreen()));
    _refresh();
  }
}

Widget _statRow(String label, String value, Color color) {
  return Column(children: [
    Text(label,
        style: TextStyle(fontSize: 12, color: Colors.grey[600])),
    Text(value,
        style: TextStyle(
            fontSize: 16, fontWeight: FontWeight.bold, color: color))
  ]);
}
