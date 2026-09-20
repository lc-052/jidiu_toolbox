import 'package:flutter/material.dart';
import 'editor_screen.dart';
import '../../../shared/widgets/common_app_bar.dart';
import '../models/memo.dart';
import '../services/memo_service.dart';

class MemoListScreen extends StatefulWidget {
  const MemoListScreen({super.key});

  @override
  State<MemoListScreen> createState() => _MemoListScreenState();
}

class _MemoListScreenState extends State<MemoListScreen> {
  late final _service = MemoService();
  List<Memo> _memos = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    setState(() => _memos = _service.getAll());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(title: '薄望录'),
      body: SafeArea(
        child: _memos.isEmpty
            ? const _EmptyState()
            : ListView.builder(
                itemCount: _memos.length,
                itemBuilder: (context, index) {
                  final memo = _memos[index];
                  return ListTile(
                    title: Text(memo.title.isEmpty ? '无标题' : memo.title),
                    subtitle: Text(memo.content.isEmpty ? '空' : memo.content.substring(0, memo.content.length.clamp(0, 50))),
                    trailing: Text(
                      '${memo.updatedAt.month}/${memo.updatedAt.day}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    onTap: () => _edit(memo),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _newMemo(),
        icon: const Icon(Icons.add),
        label: const Text('新建'),
      ),
    );
  }

  Future<void> _newMemo() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MemoEditorScreen()),
    );
    if (result == true) _load();
  }

  Future<void> _edit(Memo memo) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => MemoEditorScreen(memo: memo)),
    );
    if (result == true) _load();
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.note_alt_outlined, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text('暂无备忘录', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}
