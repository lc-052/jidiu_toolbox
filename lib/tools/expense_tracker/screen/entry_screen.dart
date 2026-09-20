import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../../shared/widgets/common_app_bar.dart';
import '../models/expense.dart';
import '../services/expense_service.dart';

class EntryScreen extends StatefulWidget {
  const EntryScreen({super.key});

  @override
  State<EntryScreen> createState() => _EntryScreenState();
}

class _EntryScreenState extends State<EntryScreen> {
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  String _type = ExpenseType.expense;
  String _category = '其他';
  bool _saving = false;

  final _categories = [
    '餐饮',
    '交通',
    '娱乐',
    '购物',
    '工资',
    '其他收入',
    '其他'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(title: '记一笔'),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Amount input (large)
              TextField(
                controller: _amountCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.displayMedium,
                decoration: const InputDecoration(
                  hintText: '0.00',
                  prefixText: '¥ ',
                  border: InputBorder.none,
                  hintStyle: TextStyle(fontSize: 48),
                ),
              ),
              const Divider(height: 32),

              // Type toggle
              ToggleButtons(
                isSelected: [
                  _type == ExpenseType.expense,
                  _type == ExpenseType.income
                ],
                onPressed: (i) {
                  setState(() {
                    _type = i == 0 ? ExpenseType.expense : ExpenseType.income;
                  });
                },
                borderRadius: BorderRadius.circular(12),
                children: const [
                  Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 24),
                      child: Text('支出')),
                  Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 24),
                      child: Text('收入')),
                ],
              ),
              const SizedBox(height: 16),

              // Category dropdown
              DropdownButtonFormField<String>(
                initialValue: _category,
                decoration: const InputDecoration(labelText: '分类'),
                items: _categories
                    .map((c) =>
                        DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setState(() => _category = v!),
              ),
              const SizedBox(height: 16),

              // Note
              TextField(
                controller: _noteCtrl,
                decoration: const InputDecoration(labelText: '备注'),
                maxLines: 2,
              ),
              const Spacer(),

              // Save button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const CircularProgressIndicator(strokeWidth: 2)
                      : const Text('保存'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    final amount = double.tryParse(_amountCtrl.text.trim());
    if (amount == null || amount <= 0) {
      return;
    }

    setState(() => _saving = true);

    try {
      final service = ExpenseService();
      await service.add(Expense(
        id: const Uuid().v4(),
        amount: amount,
        type: _type,
        category: _category,
        note: _noteCtrl.text.trim(),
      ));

      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }
}
