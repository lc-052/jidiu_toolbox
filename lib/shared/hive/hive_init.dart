// lib/shared/hive/hive_init.dart
import 'package:hive_flutter/hive_flutter.dart';

class HiveInit {
  HiveInit._();

  static const _boxes = ['expenses', 'memos', 'settings'];

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

/// Global preferences class for settings that needs to be initialized before runApp
class AppPreferences {
  static late Box _box;

  static Future<void> init() async {
    _box = Hive.box('settings');
  }

  // Brightness: system, light, dark
  static String getBrightness() => _box.get('brightness', defaultValue: 'system') as String;
  static void setBrightness(String v) => _box.put('brightness', v);

  // AI Chat
  static String getApiKey() => _box.get('apiKey', defaultValue: '') as String;
  static void setApiKey(String v) => _box.put('apiKey', v);

  static String getBaseUrl() => _box.get('baseUrl', defaultValue: 'https://api.openai.com/v1') as String;
  static void setBaseUrl(String v) => _box.put('baseUrl', v);

  static String getModelName() => _box.get('modelName', defaultValue: 'qwen-plus') as String;
  static void setModelName(String v) => _box.put('modelName', v);

  // Pomodoro
  static int getWorkMinutes() => _box.get('workMinutes', defaultValue: 25) as int;
  static void setWorkMinutes(int v) => _box.put('workMinutes', v);

  static int getRestMinutes() => _box.get('restMinutes', defaultValue: 5) as int;
  static void setRestMinutes(int v) => _box.put('restMinutes', v);
}
