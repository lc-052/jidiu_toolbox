import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../../shared/widgets/common_app_bar.dart';
import '../models/memo.dart';
import '../services/memo_service.dart';

class MemoEditorScreen extends StatefulWidget {
  final Memo? memo;
  const MemoEditorScreen({super.key, this.memo});

  @override
  State<MemoEditorScreen> createState() => _MemoEditorScreenState();
}

class _MemoEditorScreenState extends State<MemoEditorScreen> {
  late final _titleCtrl = TextEditingController(text: widget.memo?.title ?? '');
  late final _contentCtrl = TextEditingController(text: widget.memo?.content ?? '');
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(title: widget.memo == null ? '新建备忘录' : '编辑备忘录'),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Title
              TextField(
                controller: _titleCtrl,
                decoration: const InputDecoration(
                  labelText: '标题',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const Divider(height: 16),
              // Content
              Expanded(
                child: TextField(
                  controller: _contentCtrl,
                  decoration: const InputDecoration(
                    hintText: '写下你想记录的...',
                    border: InputBorder.none,
                  ),
                  maxLines: null,
                  expands: true,
                ),
              ),
              const SizedBox(height: 16),
              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (widget.memo != null)
                    TextButton(
                      onPressed: () => _delete(),
                      child: const Text('删除', style: TextStyle(color: Colors.red)),
                    ),
                  SizedBox(
                    width: 100,
                    child: ElevatedButton(
                      onPressed: _saving ? null : _save,
                      child: _saving
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('保存'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final service = MemoService();
      await service.save(Memo(
        id: widget.memo?.id ?? const Uuid().v4(),
        title: _titleCtrl.text.trim(),
        content: _contentCtrl.text.trim(),
        updatedAt: widget.memo?.updatedAt,
      ));
      if (mounted) Navigator.pop(context, true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('删除备忘录？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('取消')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('删除')),
        ],
      ),
    );
    if (confirmed == true) {
      final service = MemoService();
      await service.delete(widget.memo!.id);
      if (mounted) Navigator.pop(context, true);
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }
}
