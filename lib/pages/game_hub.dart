// lib/pages/game_hub.dart — Mini Games collection
import 'package:flutter/material.dart';

class GameHubPage extends StatelessWidget {
  const GameHubPage({super.key});

  static const _games = <GameInfo>[
    GameInfo(
      title: '数字华容道',
      subtitle: '点击滑动拼图',
      icon: Icons.grid_on,
      route: 'sliding',
    ),
    GameInfo(
      title: '俄罗斯方块',
      subtitle: '经典方块消除',
      icon: Icons.sticky_note_2_rounded,
      route: 'tetris',
    ),
    GameInfo(
      title: '贪吃蛇',
      subtitle: '控制方向吃食物',
      icon: Icons.keyboard_arrow_right_rounded,
      route: 'snake',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.gamepad, color: theme.colorScheme.primary, size: 32),
                  const SizedBox(width: 12),
                  Text('小游戏', style: theme.textTheme.headlineSmall),
                ],
              ),
            ),
            const Divider(),
            // Game list
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: _games.length,
                itemBuilder: (context, index) {
                  final g = _games[index];
                  return Card(
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () => Navigator.pushNamed(context, g.route),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Icon(g.icon, color: theme.colorScheme.primary, size: 40),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(g.title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 4),
                                  Text(g.subtitle, style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey)),
                                ],
                              ),
                            ),
                            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
                          ],
                        ),
                      ),
                    ),
                  );
                },
                separatorBuilder: (context, index) => const SizedBox(height: 8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class GameInfo {
  final String title;
  final String subtitle;
  final IconData icon;
  final String route;
  const GameInfo({required this.title, required this.subtitle, required this.icon, required this.route});
}
