import 'package:flutter/material.dart';

// lib/shared/constants.dart
class AppConstants {
  AppConstants._();

  static const String appName = '寄丢工具箱';
  static const String appVersion = '0.1.0';

  // 工具元数据
  static const tools = [
    {'key': 'qr', 'title': '二维码生成器', 'icon': Icons.qr_code, 'subtitle': '输入文字或链接生成二维码'},
    {'key': 'expense', 'title': '寄丢记账', 'icon': Icons.account_balance_wallet, 'subtitle': '简易收支记录与统计'},
    {'key': 'memo', 'title': '薄望录', 'icon': Icons.note_alt, 'subtitle': '快捷备忘录'},
    {'key': 'pomodoro', 'title': '番茄钟', 'icon': Icons.timer, 'subtitle': '专注计时 25/5 循环'},
  ];
}
