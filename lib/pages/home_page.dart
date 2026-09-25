// lib/pages/home_page.dart
import 'package:flutter/material.dart';
import '../shared/constants.dart';
import '../shared/widgets/tool_card.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

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
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text('寄丢工具箱',
                  style: theme.textTheme.displaySmall),
              const SizedBox(height: 24),

              // Title
              Text('常用工具',
                  style: theme.textTheme.titleMedium),
              const SizedBox(height: 12),

              // Row 1: 二维码(0) + 番茄钟(3)
              const _ToolRow(indexes: [0, 3]),
              const SizedBox(height: 12),

              // Row 2: 寄丢记账(1) + 薄望录(2)
              const _ToolRow(indexes: [1, 2]),
            ],
          ),
        ),
      ),
    );
  }
}

class _ToolRow extends StatelessWidget {
  final List<int> indexes;
  const _ToolRow({required this.indexes});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = (constraints.maxWidth - 12) / 2;
        return Row(
          children: indexes.map((idx) {
            final t = AppConstants.tools[idx];
            return Expanded(
              child: SizedBox(
                width: width,
                child: ToolCard(
                  icon: t['icon'] as IconData,
                  title: t['title']! as String,
                  subtitle: t['subtitle']! as String,
                  onTap: () => HomePage._navigate(context, idx),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
