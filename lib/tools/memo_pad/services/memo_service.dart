import 'package:hive_flutter/hive_flutter.dart';
import '../models/memo.dart';

class MemoService {
  late final Box _box;

  MemoService() {
    _box = Hive.box('memos');
  }

  List<Memo> getAll() {
    return _box.values
        .cast<Map<dynamic, dynamic>>()
        .map(Memo.fromMap)
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  Future<void> save(Memo memo) async {
    await _box.put(memo.id, memo.toMap());
  }

  Future<void> delete(String id) async {
    await _box.delete(id);
  }
}
