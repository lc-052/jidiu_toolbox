// lib/main.dart
import 'package:flutter/material.dart';
import 'shared/hive/hive_init.dart';
import 'shared/theme/app_theme.dart';
import 'shared/app_settings.dart'; // 全局单例 AppSettings
import 'bottom_nav_bar/container.dart';
import 'bottom_nav_bar/route_registry.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await HiveInit.init();
  await AppPreferences.init();
  await AppSettings.loadFromHive(); // 加载初始主题

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late ThemeMode _themeMode;

  @override
  void initState() {
    super.initState();
    _themeMode = AppSettings.instance.themeMode;
    // 监听 AppSettings 变更，切换主题时重建 MaterialApp
    AppSettings.instance.addListener(_onThemeChanged);
  }

  @override
  void dispose() {
    AppSettings.instance.removeListener(_onThemeChanged);
    super.dispose();
  }

  void _onThemeChanged() {
    setState(() {
      _themeMode = AppSettings.instance.themeMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '寄丢工具箱',
      theme: LightTheme.theme,
      darkTheme: DarkTheme.theme,
      themeMode: _themeMode,
      home: const BottomNavBarContainer(),
      onGenerateRoute: (settings) {
        final builder = getRoutes[settings.name];
        if (builder != null) return MaterialPageRoute(builder: builder, settings: settings);
        return null;
      },
    );
  }
}
