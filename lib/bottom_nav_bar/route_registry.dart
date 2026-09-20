import 'package:flutter/material.dart';
import '../tools/qr_code_generator/qr_screen.dart';
import '../tools/ai_chat/chat_screen.dart';

import '../tools/memo_pad/screen/list_screen.dart';
import '../tools/expense_tracker/screen/list_screen.dart';

import '../tools/pomodoro_timer/pomodoro_screen.dart';

// Routes are accumulated here. Future tasks append to this map.
Map<String, WidgetBuilder> get getRoutes => {
      'qr': (context) => const QrScreen(),
      'ai_chat': (context) => const ChatScreen(),
      'expense': (context) => const ExpenseListScreen(),
      'memo': (context) => const MemoListScreen(),
      'pomodoro': (context) => const PomodoroScreen(),
    };
