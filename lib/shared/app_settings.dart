// lib/shared/app_settings.dart
import 'package:flutter/material.dart';
import 'hive/hive_init.dart';

/// 全局 AppSettings —— 无循环依赖，任何模块可安全引用
class AppSettings extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;

  static final AppSettings instance = AppSettings._();

  ThemeMode get themeMode => _themeMode;

  AppSettings._();

  /// 从 Hive 加载初始主题
  static Future<void> loadFromHive() async {
    final mode = AppPreferences.getBrightness();
    switch (mode) {
      case 'light':  AppSettings.instance._themeMode = ThemeMode.light; break;
      case 'dark':   AppSettings.instance._themeMode = ThemeMode.dark; break;
      default:       AppSettings.instance._themeMode = ThemeMode.system; break;
    }
  }

  void setBrightness(String v) {
    switch (v) {
      case 'light':  _themeMode = ThemeMode.light; break;
      case 'dark':   _themeMode = ThemeMode.dark; break;
      default:       _themeMode = ThemeMode.system; break;
    }
    notifyListeners();
  }
}
