// lib/pages/tools_page.dart
import 'package:flutter/material.dart';
import '../shared/constants.dart';
import '../shared/widgets/tool_card.dart';

class ToolsPage extends StatelessWidget {
  const ToolsPage({super.key});

  static const _toolRoutes = <String, String>{
    'qr': 'qr',
    'ai_chat': 'ai_chat',
    'expense': 'expense',
    'memo': 'memo',
    'pomodoro': 'pomodoro',
  };

  static void _navigate(BuildContext ctx, int toolIndex) {
    final key = AppConstants.tools[toolIndex]['key']!;
    final route = _toolRoutes[key];
    if (route != null) Navigator.pushNamed(ctx, route);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: GridView.builder(
            itemCount: 6, // 5 tools + 1 placeholder
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
            ),
            itemBuilder: (context, index) {
              if (index >= AppConstants.tools.length) {
                // Placeholder slot
                return const _PlaceholderCard();
              }
              final t = AppConstants.tools[index];
              return ToolCard(
                icon: t['icon'] as IconData,
                title: t['title'] as String,
                subtitle: t['subtitle'] as String,
                onTap: () => ToolsPage._navigate(context, index),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _PlaceholderCard extends StatelessWidget {
  const _PlaceholderCard();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Center(
        child: Text(
          '🔒 预留',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      ),
    );
  }
}
