// lib/pages/tools_page.dart
import 'package:flutter/material.dart';
import '../shared/constants.dart';
import '../shared/widgets/tool_card.dart';

class ToolsPage extends StatelessWidget {
  const ToolsPage({super.key});

  static const _toolRoutes = <String, String>{
    'qr': 'qr',
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
            itemCount: AppConstants.tools.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
            ),
            itemBuilder: (context, index) {
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
