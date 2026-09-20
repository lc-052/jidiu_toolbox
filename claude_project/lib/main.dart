// lib/main.dart
import 'package:flutter/material.dart';
import 'shared/hive/hive_init.dart';
import 'shared/theme/app_theme.dart';
import 'bottom_nav_bar/container.dart';
import 'bottom_nav_bar/route_registry.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await HiveInit.init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '寄丢工具箱',
      theme: LightTheme.theme,
      darkTheme: DarkTheme.theme,
      themeMode: ThemeMode.system,
      home: const BottomNavBarContainer(),
      onGenerateRoute: (settings) {
        final builder = getRoutes[settings.name];
        if (builder != null) return MaterialPageRoute(builder: builder, settings: settings);
        return null;
      },
    );
  }
}
