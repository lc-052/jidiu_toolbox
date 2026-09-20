// lib/bottom_nav_bar/container.dart
import 'package:flutter/material.dart';
import '../pages/home_page.dart';
import '../pages/tools_page.dart';
import '../pages/settings_page.dart';

class BottomNavBarContainer extends StatefulWidget {
  const BottomNavBarContainer({super.key});

  @override
  State<BottomNavBarContainer> createState() => _BottomNavBarContainerState();
}

class _BottomNavBarContainerState extends State<BottomNavBarContainer> {
  int _currentIndex = 0;

  final _pages = [
    const HomePage(),
    const ToolsPage(),
    const SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: '首页'),
          NavigationDestination(icon: Icon(Icons.grid_view_outlined), selectedIcon: Icon(Icons.grid_view), label: '工具'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: '设置'),
        ],
      ),
    );
  }
}
