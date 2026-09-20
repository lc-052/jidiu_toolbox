// lib/shared/hive/hive_init.dart
import 'package:hive_flutter/hive_flutter.dart';

class HiveInit {
  HiveInit._();

  static const _boxes = ['expenses', 'memos'];

  static Future<void> init() async {
    await Hive.initFlutter();
    for (final name in _boxes) {
      if (!Hive.isBoxOpen(name)) {
        await Hive.openBox(name);
      }
    }
  }

  static Box<T> box<T>(String name) => Hive.box<T>(name);
}
