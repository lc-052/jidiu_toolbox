# 寄丢工具箱 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 从零搭建一个 Flutter Android 工具箱 App，包含底部导航栏、5 个实用工具和完整的数据持久化层。

**Architecture:** 模块化设计，每个工具独立文件夹内含 model/service/view。共享层统一管理主题、Hive 存储和通用组件。使用 StatefulWidget + setState 处理局部状态，避免引入额外状态管理包。底部 3 Tab 导航通过 Navigator.push/pop 进入各工具详情页。

**Tech Stack:** Flutter 3.x + Dart, Hive 本地存储, qr_flutter, http, Material Design 3

**Spec:** `docs/superpowers/specs/2026-09-20-jidiu-toolbox-design.md`

## Global Constraints

- 依赖核心包仅 4 个：hive、hive_flutter、path_provider、qr_flutter、http
- 不使用 Provider/Riverpod/Bloc，全部用 StatefulWidget + setState
- 所有工具名称必须使用原名：二维码生成器、有机交流电灯、寄丢记账、薄望录、番茄钟
- 首页常用工具网格布局：第一行左「二维码」、右「番茄钟」；第二行左「寄丢记账」、右「有机交流电灯」；第三行单独一行「薄望录」
- 支持深色/浅色模式，适配不同尺寸手机屏幕
- 遵循 MD3 设计规范，Scaffold 作为主要页面布局

---

### Task 1: 创建 Flutter 项目脚手架

**Files:**
- Create: `pubspec.yaml` — 项目配置和依赖声明
- Create: `android/app/src/main/AndroidManifest.xml` — Android 清单文件
- Create: `lib/main.dart` — 应用入口点
- Create: `assets/icons/placeholder.png` — 自定义图标占位

**Interfaces:**
- Consumes: none (first task)
- Produces: Flutter 项目可运行基础结构

- [ ] **Step 1: 初始化 Flutter 项目**

```bash
cd C:\Users\lc\Desktop\flutter\claude_project
flutter create . --project-name jidiu_toolbox --platform android --org com.jidiu
```

此命令在当前目录初始化 Flutter 项目。`--project-name` 设置应用 ID 前缀。

- [ ] **Step 2: 写入 pubspec.yaml 依赖**

替换生成的 `pubspec.yaml` 中的 dependencies 部分为：

```yaml
dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.8
  # Hive 本地存储
  hive: ^2.2.3
  hive_flutter: ^1.1.0
  path_provider: ^2.1.4
  # QR 码生成
  qr_flutter: ^4.1.0
  # AI 对话 HTTP 请求
  http: ^1.2.2
```

同时更新 flutter 的 assets 引用：
```yaml
flutter:
  uses-material-design: true
  assets:
    - assets/icons/
```

- [ ] **Step 3: 写入 AndroidManifest.xml（最小权限）**

确保 `AndroidManifest.xml` 包含：
```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <application
        android:label="寄丢工具箱"
        android:name="${applicationName}"
        android:icon="@mipmap/ic_launcher"
        android:enableOnBackInvokedCallback="true">
        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:launchMode="singleTop"
            android:taskAffinity=""
            android:theme="@style/LaunchTheme"
            android:configChanges="orientation|keyboardHidden|keyboard|screenSize|smallestScreenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode"
            android:hardwareAccelerated="true"
            android:windowSoftInputMode="adjustResize">
            <meta-data
                android:name="io.flutter.embedding.android.NormalTheme"
                android:resource="@style/NormalTheme"/>
            <intent-filter>
                <action android:name="android.intent.action.MAIN"/>
                <category android:name="android.intent.category.LAUNCHER"/>
            </intent-filter>
        </activity>
        <meta-data
            android:name="flutterEmbedding"
            android:value="2"/>
    </application>
    <queries>
        <intent>
            <action android:name="android.intent.action.PROCESS_TEXT"/>
            <data android:mimeType="text/plain"/>
        </intent>
    </queries>
</manifest>
```

关键改动：
- `android:label` 设为 "寄丢工具箱"
- 添加 `<queries>` intent filter（用于 text processing）
- 保留默认 activity 配置

- [ ] **Step 4: 创建图标占位文件**

创建 `assets/icons/placeholder.png`（任意 1x1 像素 PNG）。后续替换为实际应用图标。

- [ ] **Step 5: 运行项目验证启动**

```bash
flutter pub get
flutter run
```

确认项目在模拟器或真机上正常启动，显示空白但无错误。

- [ ] **Step 6: Commit**

```bash
git init
git add .
git commit -m "feat: initialize Flutter project scaffold"
```

---

### Task 2: 构建共享基础设施

**Files:**
- Create: `lib/shared/constants.dart` — 应用常量
- Create: `lib/shared/theme/light_theme.dart` — 浅色主题
- Create: `lib/shared/theme/dark_theme.dart` — 深色主题
- Create: `lib/shared/theme/app_theme.dart` — 主题切换逻辑
- Create: `lib/shared/hive/hive_init.dart` — Hive 初始化与 Box 获取
- Create: `lib/shared/widgets/common_app_bar.dart` — 统一 AppBar 组件
- Create: `lib/shared/widgets/tool_card.dart` — 工具卡片组件（用于首页/工具页）
- Modify: `lib/main.dart` — 主入口对接共享层

**Interfaces:**
- Consumes: Task 1 的项目结构
- Produces: 可在其他任务中直接 import 的共享模块
  - `AppConstants.appName` → "寄丢工具箱"
  - `AppTheme.lightThemeData` / `AppTheme.darkThemeData`
  - `HiveInit.initHive()` → Future
  - `CommonAppBar(title)` → StatelessWidget
  - `ToolCard(icon, title, subtitle, onTap)` → StatelessWidget

- [ ] **Step 1: 创建 constants.dart**

```dart
// lib/shared/constants.dart
class AppConstants {
  AppConstants._();
  
  static const String appName = '寄丢工具箱';
  static const String appVersion = '0.1.0';
  
  // 工具元数据
  static const tools = [
    {'key': 'qr', 'title': '二维码生成器', 'icon': Icons.qr_code, 'subtitle': '输入文字或链接生成二维码'},
    {'key': 'ai_chat', 'title': '有机交流电灯', 'icon': Icons.lightbulb, 'subtitle': '接入大模型的智能对话'},
    {'key': 'expense', 'title': '寄丢记账', 'icon': Icons.account_balance_wallet, 'subtitle': '简易收支记录与统计'},
    {'key': 'memo', 'title': '薄望录', 'icon': Icons.note_alt, 'subtitle': '快捷备忘录'},
    {'key': 'pomodoro', 'title': '番茄钟', 'icon': Icons.timer, 'subtitle': '专注计时 25/5 循环'},
  ];
}
```

- [ ] **Step 2: 创建 light_theme.dart 和 dark_theme.dart**

```dart
// lib/shared/theme/light_theme.dart
import 'package:flutter/material.dart';

class LightTheme {
  LightTheme._();
  
  static ThemeData get theme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorSchemeSeed: Colors.blue,
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      elevation: 0,
    ),
    cardTheme: CardTheme(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white,
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      filled: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
    ),
  );
}
```

```dart
// lib/shared/theme/dark_theme.dart
import 'package:flutter/material.dart';

class DarkTheme {
  DarkTheme._();
  
  static ThemeData get theme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorSchemeSeed: Colors.blue,
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      elevation: 0,
    ),
    cardTheme: CardTheme(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: const Color(0xFF1E1E1E),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      filled: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
    ),
  );
}
```

- [ ] **Step 3: 创建 app_theme.dart**

```dart
// lib/shared/theme/app_theme.dart
export 'light_theme.dart' show LightTheme;
export 'dark_theme.dart' show DarkTheme;
```

这个文件是命名空间文件，方便 `import` 时带主题名前缀。

- [ ] **Step 4: 创建 Hive 初始化模块**

```dart
// lib/shared/hive/hive_init.dart
import 'package:hive_flutter/hive_flutter.dart';

class HiveInit {
  HiveInit._();
  
  static const _boxes = ['expenses', 'memos'];
  
  static Future<void> init() async {
    await Hive.initFlutter();
    for (final name in _boxes) {
      if (!Hive.isBoxOpen(name)) {
        await Hive.openBox(name);
      }
    }
  }
  
  static Box<T> box<T>(String name) => Hive.box<T>(name);
}
```

目前打开两个盒子：`expenses` 和 `memos`。AI 聊天记录暂存内存，不持久化到 Hive。

- [ ] **Step 5: 创建 CommonAppBar 组件**

```dart
// lib/shared/widgets/common_app_bar.dart
import 'package:flutter/material.dart';

class CommonAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  
  const CommonAppBar({super.key, required this.title, this.actions, this.leading});
  
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
  
  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title),
      centerTitle: true,
      actions: actions,
      leading: leading,
    );
  }
}
```

- [ ] **Step 6: 创建 ToolCard 组件**

```dart
// lib/shared/widgets/tool_card.dart
import 'package:flutter/material.dart';

class ToolCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  
  const ToolCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: theme.colorScheme.primary),
              const SizedBox(height: 12),
              Text(
                title,
                style: theme.textTheme.bodyLarge,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 7: 更新 main.dart 入口文件**

```dart
// lib/main.dart
import 'package:flutter/material.dart';
import 'shared/hive/hive_init.dart';
import 'shared/theme/app_theme.dart';

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
      home: Scaffold(body: const Center(child: Text('待实现'))),
    );
  }
}
```

关键点：
- `WidgetsFlutterBinding.ensureInitialized()` 保证异步初始化完成后再启动
- `HiveInit.init()` 在 `runApp` 之前调用
- `themeMode: ThemeMode.system` 跟随系统
- 暂时显示 "待实现" 占位，后续逐步替换页面

- [ ] **Step 8: 验证并 Commit**

```bash
flutter run
```

确认 App 能正常启动，且浅色/深色模式均正确加载。然后提交：

```bash
git add lib/ pubspec.yaml android/
git commit -m "feat: add shared infrastructure (theme, hive, widgets)"
```

---

### Task 3: 实现底部导航栏 + 首页

**Files:**
- Create: `lib/pages/home_page.dart` — 首页
- Create: `lib/bottom_nav_bar/navigation_state.dart` — 底部导航状态容器
- Create: `lib/bottom_nav_bar/tab_item.dart` — 导航项定义
- Modify: `lib/main.dart` — 替换占位为导航

**Interfaces:**
- Consumes:
  - `AppConstants.tools` — 工具元数据列表
  - `ToolCard` — 卡片组件
  - `CommonAppBar` — 顶部栏
- Produces:
  - `HomePage` → 首页组件
  - `BottomNavBarContainer` → 含底部导航的根页面

- [ ] **Step 1: 创建 NavigationState 状态类**

```dart
// lib/bottom_nav_bar/navigation_state.dart
import 'package:flutter/material.dart';

abstract class NavItem {
  final String title;
  final IconData icon;
  final Widget page;
  
  const NavItem({required this.title, required this.icon, required this.page});
}
```

这是一个纯抽象类，用于定义导航项的类型约束。

- [ ] **Step 2: 创建 HomePage**

```dart
// lib/pages/home_page.dart
import 'package:flutter/material.dart';
import '../shared/constants.dart';
import '../shared/widgets/tool_card.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final navKey = AppConstants.tools.map((t) => (t['key']!, t['icon'] as IconData, t['title']!, t['subtitle']!)).toList();
    
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('欢迎使用', style: theme.textTheme.headlineMedium),
                  const SizedBox(height: 4),
                  Text('寄丢工具箱', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 24),
                  Text('📱 常用工具', style: theme.textTheme.titleMedium),
                ],
              ),
            ),
          ),
          // 第一行：二维码 + 番茄钟
          SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.0,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final pair = [(0, 2), (1, 4)][index];
                return ToolCard(
                  icon: AppConstants.tools[pair.$2]['icon'] as IconData,
                  title: AppConstants.tools[pair.$2]['title']!,
                  subtitle: AppConstants.tools[pair.$2]['subtitle']!,
                  onTap: () {}, // TODO: 路由跳转
                );
              },
              childCount: 2,
            ),
          ),
          // ... 更多 SliverGrid ...
        ],
      ),
    );
  }
}
```

**简化版实现思路：** 实际上首页更简单的做法是使用 GridView / Table / Flex 而不是复杂的 Sliver。因为工具数量固定为 5 个。

改为：

```dart
// lib/pages/home_page.dart
import 'package:flutter/material.dart';
import '../shared/constants.dart';
import '../shared/widgets/tool_card.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});
  
  void _onToolTap(BuildContext context, int index) {
    // TODO: 根据 index 跳转到对应工具页面
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
              Text('📱 常用工具',
                  style: theme.textTheme.titleMedium),
              const SizedBox(height: 12),
              
              // Row 1: 二维码(0) + 番茄钟(4)
              const _ToolRow(indexes: [0, 4]),
              const SizedBox(height: 12),
              
              // Row 2: 寄丢记账(2) + 有机交流电灯(1)
              const _ToolRow(indexes: [2, 1]),
              const SizedBox(height: 12),
              
              // Row 3: 薄望录(3) 单独一行
              const _ToolFullRow(index: 3),
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
                  title: t['title']!,
                  subtitle: t['subtitle']!,
                  onTap: () {},
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _ToolFullRow extends StatelessWidget {
  final int index;
  const _ToolFullRow({required this.index});
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = AppConstants.tools[index];
    
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Icon(t['icon'] as IconData,
                   size: 32, color: theme.colorScheme.primary),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t['title']!, style: theme.textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(t['subtitle']!, style: theme.textTheme.bodyMedium),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 3: 创建 BottomNavBarContainer**

```dart
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
```

注意：这里用的是 `Scaffold` 嵌套 `Scaffold`。由于每个子页都有自己的 `SafeArea`，最外层不需要重复的 SafeArea。

- [ ] **Step 4: 更新 main.dart**

```dart
// lib/main.dart (build method 中)
import '../bottom_nav_bar/container.dart';

// ... 在 MaterialApp 的 home: 处 ...
home: const BottomNavBarContainer(),
```

- [ ] **Step 5: 验证并 Commit**

运行项目，确认底部导航栏正常，三个 Tab 均可切换（此时只有首页有内容，工具页/设置页还是占位）。

```bash
git add lib/bottom_nav_bar/ lib/pages/home_page.dart lib/main.dart
git commit -m "feat: add bottom navigation bar and home page"
```

---

### Task 4: 实现工具页

**Files:**
- Create: `lib/pages/tools_page.dart` — 工具网格页

**Interfaces:**
- Consumes:
  - `AppConstants.tools` — 5 个工具的元数据
  - `ToolCard` — 复用已有卡片组件
- Produces:
  - `ToolsPage` — 展示所有工具的可点击网格

- [ ] **Step 1: 创建 ToolsPage**

```dart
// lib/pages/tools_page.dart
import 'package:flutter/material.dart';
import '../shared/constants.dart';
import '../shared/widgets/tool_card.dart';

class ToolsPage extends StatelessWidget {
  const ToolsPage({super.key});
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: GridView.builder(
            itemCount: 6, // 5 个工具 + 1 预留位
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
            ),
            itemBuilder: (context, index) {
              if (index >= AppConstants.tools.length) {
                // 预留位
                return const _PlaceholderCard();
              }
              final t = AppConstants.tools[index];
              return ToolCard(
                icon: t['icon'] as IconData,
                title: t['title']!,
                subtitle: t['subtitle']!,
                onTap: () {}, // TODO: 路由跳转
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
```

- [ ] **Step 2: 验证并 Commit**

```bash
git add lib/pages/tools_page.dart
git commit -m "feat: add tools page with grid layout"
```

---

### Task 5: 实现设置页

**Files:**
- Create: `lib/pages/settings_page.dart` — 设置页
- Modify: `lib/bottom_nav_bar/container.dart` — 导入 SettingsPage

**Interfaces:**
- Consumes: Material 组件库
- Produces: `SettingsPage` — 包含外观设置、API Key 设置、番茄时长设置

- [ ] **Step 1: 创建 SettingsPage**

```dart
// lib/pages/settings_page.dart
import 'package:flutter/material.dart';
import '../shared/constants.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});
  
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String _brightness = 'system'; // system, light, dark
  String _apiKey = '';
  String _baseUrl = 'https://api.openai.com/v1';
  int _workMinutes = 25;
  int _restMinutes = 5;
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionTitle('外观设置'),
              RadioListTile<String>(
                title: const Text('跟随系统'),
                value: 'system',
                groupValue: _brightness,
                onChanged: (v) => setState(() => _brightness = v!),
              ),
              RadioListTile<String>(
                title: const Text('浅色'),
                value: 'light',
                groupValue: _brightness,
                onChanged: (v) => setState(() => _brightness = v!),
              ),
              RadioListTile<String>(
                title: const Text('深色'),
                value: 'dark',
                groupValue: _brightness,
                onChanged: (v) => setState(() => _brightness = v!),
              ),
              const Divider(height: 32),
              _SectionTitle('AI 聊天 (电灯)'),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'API Key',
                  prefixIcon: Icon(Icons.key),
                ),
                obscureText: true,
                onChanged: (v) => setState(() => _apiKey = v),
              ),
              const SizedBox(height: 12),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Base URL',
                  prefixIcon: Icon(Icons.link),
                ),
                onChanged: (v) => setState(() => _baseUrl = v),
              ),
              const SizedBox(height: 8),
              const Text('示例: https://api.openai.com/v1',
                  style: TextStyle(color: Colors.grey, fontSize: 12)),
              const Divider(height: 32),
              _SectionTitle('番茄钟'),
              TextField(
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: '工作时长',
                  prefixIcon: const Icon(Icons.timer),
                  suffixText: 'min',
                ),
                onChanged: (v) => setState(() => _workMinutes = int.tryParse(v) ?? 25),
              ),
              const SizedBox(height: 12),
              TextField(
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: '休息时长',
                  prefixIcon: const Icon(Icons.pause_circle),
                  suffixText: 'min',
                ),
                onChanged: (v) => setState(() => _restMinutes = int.tryParse(v) ?? 5),
              ),
              const Divider(height: 32),
              _SectionTitle('关于'),
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: Text(AppConstants.appName),
                subtitle: Text('版本 ${AppConstants.appVersion}'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);
  
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 8),
      child: Text(text,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              )),
    );
  }
}
```

- [ ] **Step 2: 更新 container.dart 导入**

在 `container.dart` 中添加 `import`：
```dart
import '../pages/settings_page.dart';
```

- [ ] **Step 3: 验证并 Commit**

运行项目，点击「设置」Tab，确认各项设置选项均正确显示。

```bash
git add lib/pages/settings_page.dart lib/bottom_nav_bar/container.dart
git commit -m "feat: add settings page"
```

---

### Task 6: 实现二维码生成器

**Files:**
- Create: `lib/tools/qr_code_generator/qr_screen.dart` — QR 生成页面
- Create: `lib/tools/qr_code_generator/widgets/qr_output.dart` — QR 码输出展示组件
- Create: `lib/bottom_nav_bar/route_registry.dart` — 路由注册表
- Modify: `lib/bottom_nav_bar/container.dart` — 注入路由
- Modify: `lib/pages/home_page.dart` — 添加工具卡片点击跳转
- Modify: `lib/pages/tools_page.dart` — 添加工具卡片点击跳转
- Modify: `pubspec.yaml` — 确认 qr_flutter 已添加

**Interfaces:**
- Consumes:
  - `ToolCard.onTap` 回调（Task 3/4）
- Produces:
  - `QrScreen` — 完整的二维码生成界面
  - 路由键 `'qr'` → QrScreen
  - `Navigator.pushNamed(context, 'qr')` 可触发跳转

- [ ] **Step 1: 安装依赖**

```bash
flutter pub get
```

确保 `pubspec.yaml` 中包含 `qr_flutter: ^4.1.0`。

- [ ] **Step 2: 创建 QrOutput 组件**

```dart
// lib/tools/qr_code_generator/widgets/qr_output.dart
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class QrOutput extends StatelessWidget {
  final String data;
  
  const QrOutput({super.key, required this.data});
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    final bgColor = isLight ? Colors.white : Colors.black;
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: QrImageView(
          data: data,
          version: QrVersions.auto,
          size: 200.0,
          backgroundColor: bgColor,
        ),
      ),
    );
  }
}
```

- [ ] **Step 3: 创建 QrScreen**

```dart
// lib/tools/qr_code_generator/qr_screen.dart
import 'package:flutter/material.dart';
import '../../shared/widgets/common_app_bar.dart';
import 'widgets/qr_output.dart';

class QrScreen extends StatefulWidget {
  const QrScreen({super.key});
  
  @override
  State<QrScreen> createState() => _QrScreenState();
}

class _QrScreenState extends State<QrScreen> {
  final _controller = TextEditingController();
  String _output = '';
  bool _visible = false;
  
  void _generate() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _output = text;
      _visible = true;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CommonAppBar(title: '二维码生成器'),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextField(
                controller: _controller,
                decoration: const InputDecoration(
                  hintText: '输入文字或链接...',
                  prefixIcon: Icon(Icons.qr_code_scanner),
                ),
                maxLines: null,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _generate(),
              ),
              const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _generate,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                  ),
                  child: const Text('生成二维码'),
                ),
              const Spacer(),
              if (_visible && _output.isNotEmpty)
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        QrOutput(data: _output),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            OutlinedButton.icon(
                              icon: const Icon(Icons.copy),
                              label: const Text('复制文本'),
                              onPressed: () {
                                // TODO: Clipboard.setData
                              },
                            ),
                            OutlinedButton.icon(
                              icon: const Icon(Icons.download),
                              label: const Text('保存'),
                              onPressed: () {
                                // TODO: 保存图片
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              if (!_visible)
                Expanded(
                  child: Center(
                    child: Icon(Icons.qr_code_2,
                        size: 80, color: Colors.grey[400]),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: 创建路由注册表**

```dart
// lib/bottom_nav_bar/route_registry.dart
import 'package:flutter/material.dart';
import '../tools/qr_code_generator/qr_screen.dart';

Map<String, WidgetBuilder> get routes => {
      'qr': (context) => const QrScreen(),
      // TODO: later tasks will add more routes here
    };
```

- [ ] **Step 5: 注入路由到 container.dart**

修改 `container.dart`：

```dart
import 'route_registry.dart';

// 在 BottomNavBarContainer widget 中
return MaterialApp( // <-- 不再在 main.dart 里放 MaterialApp
  navigatorKey: _navKey,
  routes: routeRegistry.routes,
  home: Scaffold(...), // <-- 去掉 MaterialApp wrapper
);
```

更好的方案：保持 main.dart 的 MaterialApp，但用 `onGenerateRoute`：

```dart
// main.dart
import 'bottom_nav_bar/route_registry.dart';

// 在 MaterialApp 中
onGenerateRoute: (settings) {
  final builder = routes[settings.name];
  if (builder != null) {
    return MaterialPageRoute(builder: builder, settings: settings);
  }
  return null;
},
```

- [ ] **Step 6: 更新 home_page.dart 和 tools_page.dart 的 onTap**

```dart
// 在 ToolCard 的 onTap 中使用：
onTap: () => Navigator.pushNamed(context, 'qr'),
```

对于首页：
```dart
// row 0: 二维码(0) → qr
// row 0: 番茄钟(4) → pomodoro (TODO)
onTap: () {
  switch (toolIndex) {
    case 0: Navigator.pushNamed(context, 'qr'); break;
    // ... other cases
  }
}
```

使用 Map 映射更高效：
```dart
static const _routeMap = {
  'qr': 'qr',
  'ai_chat': 'ai_chat',
  'expense': 'expense',
  'memo': 'memo',
  'pomodoro': 'pomodoro',
};
```

- [ ] **Step 7: 验证并 Commit**

运行项目，依次测试：
1. 首页/工具页点击「二维码生成器」→ 进入 QR 页面
2. 输入文字并点击生成 → 看到 QR 码渲染
3. 返回按钮回到对应 Tab

```bash
git add lib/tools/qr_code_generator/ lib/bottom_nav_bar/route_registry.dart lib/pages/*.dart pubspec.yaml
git commit -m "feat: add QR code generator tool"
```

---

### Task 7: 实现有机交流电灯 (AI Chat)

**Files:**
- Create: `lib/tools/ai_chat/models/chat_message.dart` — 消息数据类
- Create: `lib/tools/ai_chat/services/api_client.dart` — API 调用客户端
- Create: `lib/tools/ai_chat/chat_screen.dart` — 聊天主页面
- Modify: `lib/bottom_nav_bar/route_registry.dart` — 添加 ai_chat 路由

**Interfaces:**
- Consumes:
  - `CommonAppBar` (共享组件)
  - `SettingsPage` 中的 `_apiKey` 和 `_baseUrl` 值
- Produces:
  - `ChatScreen` — 完整的聊天界面
  - `ApiClient(baseUrl, apiKey)` → Future<String> sendMessage(String prompt, List<Message> history)
  - SSE 流式响应解析

- [ ] **Step 1: 创建 ChatMessage 模型**

```dart
// lib/tools/ai_chat/models/chat_message.dart
enum MessageRole { system, user, assistant }

class ChatMessage {
  final MessageRole role;
  final String content;
  final DateTime timestamp;
  
  ChatMessage({
    required this.role,
    required this.content,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
  
  Map<String, dynamic> toJson() => {
        'role': role.name,
        'content': content,
      };
  
  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        role: MessageRole.values.byName(json['role']),
        content: json['content'],
      );
}
```

- [ ] **Step 2: 创建 ApiClient**

```dart
// lib/tools/ai_chat/services/api_client.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/chat_message.dart';

class ApiClient {
  final String baseUrl;
  final String apiKey;
  
  ApiClient({required this.baseUrl, required this.apiKey});
  
  Future<String> send({
    required String userMessage,
    required List<ChatMessage> history,
    bool stream = true,
  }) async {
    // 构造 messages 数组
    final messages = [
      // system prompt
      {'role': 'system', 'content': '你是一个有用的助手。请用中文回答。'},
      // historical messages
      ...history.map((m) => m.toJson()),
      // new user message
      {'role': 'user', 'content': userMessage},
    ];
    
    final url = Uri.parse('$baseUrl/chat/completions');
    
    if (stream) {
      // SSE 流式请求
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'model': '', 'messages': messages, 'stream': true}),
      );
      
      if (response.statusCode == 200) {
        // 解析 SSE chunks
        return _parseStream(response.body);
      } else {
        throw Exception('API error: ${response.statusCode}');
      }
    } else {
      // 非流式请求
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'model': '', 'messages': messages, 'stream': false}),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final choices = data['choices'] as List;
        return choices[0]['message']['content'] as String;
      } else {
        throw Exception('API error: ${response.statusCode}');
      }
    }
  }
  
  String _parseStream(String responseBody) {
    // 简单 SSE 解析：合并所有 delta.content
    final parts = <String>[];
    for (final line in responseBody.split('\n')) {
      if (line.startsWith('data: ')) {
        final data = line.substring(6);
        if (data == '[DONE]') continue;
        try {
          final chunk = jsonDecode(data) as Map<String, dynamic>;
          final delta = chunk['delta'] as Map<String, dynamic>?;
          final content = delta?['content'] as String?;
          if (content != null) parts.add(content);
        } catch (_) {}
      }
    }
    return parts.join();
  }
}
```

- [ ] **Step 3: 创建 ChatScreen**

```dart
// lib/tools/ai_chat/chat_screen.dart
import 'package:flutter/material.dart';
import '../../shared/widgets/common_app_bar.dart';
import 'models/chat_message.dart';
import 'services/api_client.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});
  
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messages = <ChatMessage>[];
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  bool _loading = false;
  
  // 从 Settings 读取的配置
  String _apiKey = '';
  String _baseUrl = 'https://api.openai.com/v1';
  
  @override
  void initState() {
    super.initState();
    // TODO: 从 Hive 读取 saved API key 和 base url
    // For now, hardcode or read from provider (none used yet)
    _apiKey = ''; // Read from settings when implemented
    _baseUrl = 'https://api.openai.com/v1';
  }
  
  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _loading) return;
    
    setState(() {
      _messages.add(ChatMessage(role: MessageRole.user, content: text));
      _loading = true;
    });
    _controller.clear();
    
    try {
      final client = ApiClient(apiKey: _apiKey, baseUrl: _baseUrl);
      final reply = await client.send(
        userMessage: text,
        history: _messages.where((m) => m.role != MessageRole.system).toList(),
      );
      
      if (mounted) {
        setState(() {
          _messages.add(ChatMessage(role: MessageRole.assistant, content: reply));
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _messages.add(ChatMessage(
            role: MessageRole.system,
            content: '⚠️ 请求失败: $e',
          ));
        });
      }
    }
    
    // Auto-scroll to bottom
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CommonAppBar(title: '有机交流电灯'),
      body: SafeArea(
        child: Column(
          children: [
            // Message list
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final msg = _messages[index];
                  if (msg.role == MessageRole.system) {
                    return SystemMessageChip(msg.content);
                  }
                  return MessageBubble(message: msg);
                },
              ),
            ),
            
            // Loading indicator
            if (_loading)
              Container(
                padding: const EdgeInsets.all(12),
                alignment: Alignment.centerLeft,
                child: const CircularProgressIndicator(strokeWidth: 2),
              ),
            
            // Input bar
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        decoration: const InputDecoration(
                          hintText: '输入消息...',
                          border: InputBorder.none,
                        ),
                        maxLines: null,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.send),
                      onPressed: _loading ? null : _sendMessage,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}

class MessageBubble extends StatelessWidget {
  final ChatMessage message;
  const MessageBubble({super.key, required this.message});
  
  @override
  Widget build(BuildContext context) {
    final isUser = message.role == MessageRole.user;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          bottom: 8,
          left: isUser ? 48 : 8,
          right: isUser ? 8 : 48,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isUser
              ? Theme.of(context).colorScheme.primaryContainer
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(message.content),
      ),
    );
  }
}

class SystemMessageChip extends StatelessWidget {
  final String content;
  const SystemMessageChip(this.content, {super.key});
  
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(content, style: TextStyle(color: Colors.orange[700])),
    );
  }
}
```

- [ ] **Step 4: 更新路由注册**

在 `route_registry.dart` 中：

```dart
import '../tools/ai_chat/chat_screen.dart';

Map<String, WidgetBuilder> get routes => {
      'qr': (context) => const QrScreen(),
      'ai_chat': (context) => const ChatScreen(),
    };
```

- [ ] **Step 5: 验证并 Commit**

测试要点：
1. 输入空 API Key 发送消息 → 应看到错误提示
2. 填入正确的 OpenAI-compatible API Key 和 Base URL → 能看到 AI 回复
3. 滚动流畅，消息气泡左右对齐正确

```bash
git add lib/tools/ai_chat/ lib/bottom_nav_bar/route_registry.dart
git commit -m "feat: add AI chat tool (有机交流电灯)"
```

---

### Task 8: 实现寄丢记账

**Files:**
- Create: `lib/tools/expense_tracker/models/expense.dart` — 数据模型 + Hive TypeAdapter
- Create: `lib/tools/expense_tracker/services/expense_service.dart` — Hive CRUD + 统计
- Create: `lib/tools/expense_tracker/screen/list_screen.dart` — 列表页面
- Create: `lib/tools/expense_tracker/screen/entry_screen.dart` — 录入页面
- Modify: `lib/bottom_nav_bar/route_registry.dart` — 添加 expense 路由
- Modify: `lib/shared/hive/hive_init.dart` — 注册 Adapter

**Interfaces:**
- Consumes:
  - `CommonAppBar`
  - `FAB` (Material 内置)
- Produces:
  - `ExpenseListView` — 按日期分组的历史列表
  - `ExpenseEntryView` — 新增/编辑表单
  - `ExpenseService` 提供 `List<Expense> getAll()`, `Future<void> add(Expense)`, `Future<void> delete(String id)`, `{double totalIncome, double totalExpense, double balance} statsForMonth(int month, int year)`

- [ ] **Step 1: 创建 Expense 模型**

```dart
// lib/tools/expense_tracker/models/expense.dart
class ExpenseType {
  const ExpenseType._();
  static const income = 'income';
  static const expense = 'expense';
}

class Expense {
  final String id;
  final double amount;
  final String type; // 'income' | 'expense'
  final String category;
  final String note;
  final DateTime createdAt;
  
  Expense({
    required this.id,
    required this.amount,
    required this.type,
    this.category = '其他',
    this.note = '',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();
  
  Map<String, dynamic> toMap() => {
        'id': id,
        'amount': amount,
        'type': type,
        'category': category,
        'note': note,
        'createdAt': createdAt.millisecondsSinceEpoch,
      };
  
  factory Expense.fromMap(Map<dynamic, dynamic> map) => Expense(
        id: map['id'] as String,
        amount: (map['amount'] as num).toDouble(),
        type: map['type'] as String,
        category: map['category'] as String,
        note: map['note'] as String,
        createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
      );
}
```

Hive TypeAdapter 使用 Hive 代码生成器，需要在 `.g.dart` 文件中由 `build_runner` 生成。在计划中标注需要运行：

```bash
dart run build_runner build --delete-conflicting-outputs
```

- [ ] **Step 2: 创建 ExpenseService**

```dart
// lib/tools/expense_tracker/services/expense_service.dart
import 'package:hive_flutter/hive_flutter.dart';
import '../models/expense.dart';

class ExpenseService {
  late final Box _box;
  
  ExpenseService() {
    _box = Hive.box('expenses');
  }
  
  List<Expense> getAll({int? year, int? month}) {
    var items = _box.values.cast<Map<dynamic, dynamic>>().map(Expense.fromMap).toList();
    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    
    if (year != null) items.removeWhere((e) => e.createdAt.year != year);
    if (month != null) items.removeWhere((e) => e.createdAt.month != month);
    
    return items;
  }
  
  Future<void> add(Expense expense) async {
    await _box.put(expense.id, expense.toMap());
  }
  
  Future<void> delete(String id) async {
    await _box.delete(id);
  }
  
  ({double income, double expense, double balance}) statsForMonth(int year, int month) {
    final items = getAll(year: year, month: month);
    double income = 0, expense = 0;
    for (final e in items) {
      if (e.type == ExpenseType.income) income += e.amount;
      else expense += e.amount;
    }
    return (income: income, expense: expense, balance: income - expense);
  }
}
```

- [ ] **Step 3: 创建 EntryScreen（录入页）**

```dart
// lib/tools/expense_tracker/screen/entry_screen.dart
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart'; // Note: may need to add dependency
import '../../../shared/widgets/common_app_bar.dart';
import '../models/expense.dart';
import '../services/expense_service.dart';

class EntryScreen extends StatefulWidget {
  const EntryScreen({super.key});
  
  @override
  State<EntryScreen> createState() => _EntryScreenState();
}

class _EntryScreenState extends State<EntryScreen> {
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  String _type = ExpenseType.expense;
  String _category = '其他';
  bool _saving = false;
  
  final _categories = ['餐饮', '交通', '娱乐', '购物', '工资', '其他收入', '其他'];
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(title: '记一笔'),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Amount input (large)
              TextField(
                controller: _amountCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.displayMedium,
                decoration: const InputDecoration(
                  hintText: '0.00',
                  prefixText: '¥ ',
                  border: InputBorder.none,
                  hintStyle: TextStyle(fontSize: 48),
                ),
              ),
              const Divider(height: 32),
              
              // Type toggle
              ToggleButtons(
                isSelected: [_type == ExpenseType.expense, _type == ExpenseType.income],
                onPressed: (i) {
                  setState(() {
                    _type = i == 0 ? ExpenseType.expense : ExpenseType.income;
                  });
                },
                borderRadius: BorderRadius.circular(12),
                children: const [
                  Padding(padding: EdgeInsets.symmetric(horizontal: 24), child: Text('支出')),
                  Padding(padding: EdgeInsets.symmetric(horizontal: 24), child: Text('收入')),
                ],
              ),
              const SizedBox(height: 16),
              
              // Category dropdown
              DropdownButtonFormField<String>(
                value: _category,
                decoration: const InputDecoration(labelText: '分类'),
                items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (v) => setState(() => _category = v!),
              ),
              const SizedBox(height: 16),
              
              // Note
              TextField(
                controller: _noteCtrl,
                decoration: const InputDecoration(labelText: '备注'),
                maxLines: 2,
              ),
              const Spacer(),
              
              // Save button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const CircularProgressIndicator(strokeWidth: 2)
                      : const Text('保存'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Future<void> _save() async {
    final amount = double.tryParse(_amountCtrl.text.trim());
    if (amount == null || amount <= 0) {
      // Show error toast
      return;
    }
    
    setState(() => _saving = true);
    
    try {
      final service = ExpenseService();
      await service.add(Expense(
        id: const Uuid().v4(),
        amount: amount,
        type: _type,
        category: _category,
        note: _noteCtrl.text.trim(),
      ));
      
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
  
  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }
}
```

> 注意：`uuid` 包是一个额外的依赖。如果希望严格限制 4 个核心包，可以用 `DateTime.now().millisecondsSinceEpoch.toString()` 代替 UUID。建议在 `pubspec.yaml` 中添加 `uuid: ^4.5.1`，它极小。

- [ ] **Step 4: 创建 ListScreen（列表页）**

```dart
// lib/tools/expense_tracker/screen/list_screen.dart
import 'package:flutter/material.dart';
import 'entry_screen.dart';
import '../../../shared/widgets/common_app_bar.dart';
import '../models/expense.dart';
import '../services/expense_service.dart';

class ListScreen extends StatefulWidget {
  const ListScreen({super.key});
  
  @override
  State<ListScreen> createState() => _ListScreenState();
}

class _ListScreenState extends State<ListScreen> {
  late final _service = ExpenseService();
  
  List<Expense> _items = [];
  ({double income, double expense, double balance}) _stats = (income: 0, expense: 0, balance: 0);
  
  @override
  void initState() {
    super.initState();
    _refresh();
  }
  
  void _refresh() {
    setState(() {
      _items = _service.getAll();
      final now = DateTime.now();
      _stats = _service.statsForMonth(now.year, now.month);
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(title: '寄丢记账'),
      body: SafeArea(
        child: Column(
          children: [
            // Summary card
            _StatsCard(stats: _stats),
            const SizedBox(height: 12),
            
            // List
            Expanded(
              child: _items.isEmpty
                  ? const _EmptyState()
                  : ListView.builder(
                      itemCount: _items.length,
                      itemBuilder: (context, index) {
                        final item = _items[index];
                        return Dismissible(
                          key: ValueKey(item.id),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 16),
                            color: Colors.red.shade100,
                            child: const Icon(Icons.delete, color: Colors.red),
                          ),
                          onDismissed: (_) {
                            _service.delete(item.id);
                            _refresh();
                          },
                          child: _ExpenseTile(item: item),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _goToEntry(),
        icon: const Icon(Icons.add),
        label: const Text('记一笔'),
      ),
    );
  }
  
  Future<void> _goToEntry() async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => const EntryScreen()));
    _refresh();
  }
}

class _StatsCard extends StatelessWidget {
  final ({double income, double expense, double balance}) stats;
  const _StatsCard({required this.stats});
  
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _StatItem('收入', '+¥${stats.income.toStringAsFixed(2)}, Colors.green),
                _StatItem('支出', '-¥${stats.expense.toStringAsFixed(2)}, Colors.red),
                _StatItem('结余', '¥${stats.balance.toStringAsFixed(2)}, Theme.of(context).colorScheme.primary),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatItem(this.label, this.value, this.color);
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        Text(value, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: color)),
      ],
    );
  }
}

class _ExpenseTile extends StatelessWidget {
  final Expense item;
  const _ExpenseTile({required this.item});
  
  @override
  Widget build(BuildContext context) {
    final isIncome = item.type == ExpenseType.income;
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: isIncome ? Colors.green.shade100 : Colors.red.shade100,
        child: Icon(
          isIncome ? Icons.arrow_downward : Icons.arrow_upward,
          color: isIncome ? Colors.green : Colors.red,
        ),
      ),
      title: Text('${item.category}${item.note.isNotEmpty ? ' - ${item.note}' : ''}'),
      subtitle: Text(item.createdAt.toLocaleDateString()),
      trailing: Text(
        '${isIncome ? '+' : '-'}¥${item.amount.toStringAsFixed(2)}',
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: isIncome ? Colors.green : Colors.red,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text('暂无记录', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}
```

- [ ] **Step 5: 更新 Hive init 注册 Adapter + 路由**

在 `hive_init.dart` 中添加 Adapter 注册（需要 build_runner 生成的 adapter.g.dart）。

在 `route_registry.dart` 中添加：
```dart
import '../tools/expense_tracker/screen/list_screen.dart';
// ...
'expense': (context) => const ListScreen(),
```

- [ ] **Step 6: 验证并 Commit**

测试：
1. 点击 FAB "记一笔" → 录入页面
2. 填写金额 → 选择类型/分类/备注 → 保存
3. 列表中看到条目，滑动删除
4. 顶部汇总卡片显示本月统计数据

```bash
git add lib/tools/expense_tracker/ lib/bottom_nav_bar/route_registry.dart
git commit -m "feat: add expense tracker tool (寄丢记账)"
```

---

### Task 9: 实现薄望录

**Files:**
- Create: `lib/tools/memo_pad/models/memo.dart` — 备忘录模型
- Create: `lib/tools/memo_pad/services/memo_service.dart` — Hive CRUD
- Create: `lib/tools/memo_pad/screen/list_screen.dart` — 列表页
- Create: `lib/tools/memo_pad/screen/editor_screen.dart` — 编辑页
- Modify: `lib/bottom_nav_bar/route_registry.dart` — 添加 memo 路由

**Interfaces:**
- Consumes:
  - `CommonAppBar`
  - Hive `memos` box
- Produces:
  - `MemoListView` — 按更新时间倒序排列的备忘录列表
  - `MemoEditorView` — 标题 + 正文编辑
  - `MemoService` → `List<Memo> getAll()`, `Future<void> save(Memo)`, `Future<void> delete(String id)`

- [ ] **Step 1: 创建 Memo 模型**

```dart
// lib/tools/memo_pad/models/memo.dart
class Memo {
  final String id;
  final String title;
  final String content;
  final DateTime updatedAt;
  
  Memo({
    required this.id,
    this.title = '',
    this.content = '',
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now();
  
  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'content': content,
        'updatedAt': updatedAt?.millisecondsSinceEpoch ?? DateTime.now().millisecondsSinceEpoch,
      };
  
  factory Memo.fromMap(Map<dynamic, dynamic> map) => Memo(
        id: map['id'] as String,
        title: map['title'] as String,
        content: map['content'] as String,
        updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] as int),
      );
}
```

- [ ] **Step 2: 创建 MemoService**

```dart
// lib/tools/memo_pad/services/memo_service.dart
import 'package:hive_flutter/hive_flutter.dart';
import '../models/memo.dart';

class MemoService {
  late final Box _box;
  
  MemoService() {
    _box = Hive.box('memos');
  }
  
  List<Memo> getAll() {
    return _box.values
        .cast<Map<dynamic, dynamic>>()
        .map(Memo.fromMap)
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }
  
  Future<void> save(Memo memo) async {
    await _box.put(memo.id, memo.toMap());
  }
  
  Future<void> delete(String id) async {
    await _box.delete(id);
  }
}
```

- [ ] **Step 3: 创建 ListScreen（备忘录列表）**

```dart
// lib/tools/memo_pad/screen/list_screen.dart
import 'package:flutter/material.dart';
import 'editor_screen.dart';
import '../../../shared/widgets/common_app_bar.dart';
import '../models/memo.dart';
import '../services/memo_service.dart';

class MemoListScreen extends StatefulWidget {
  const MemoListScreen({super.key});
  
  @override
  State<MemoListScreen> createState() => _MemoListScreenState();
}

class _MemoListScreenState extends State<MemoListScreen> {
  late final _service = MemoService();
  List<Memo> _memos = [];
  
  @override
  void initState() {
    super.initState();
    _load();
  }
  
  void _load() {
    setState(() => _memos = _service.getAll());
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(title: '薄望录'),
      body: SafeArea(
        child: _memos.isEmpty
            ? const _EmptyState()
            : ListView.builder(
                itemCount: _memos.length,
                itemBuilder: (context, index) {
                  final memo = _memos[index];
                  return ListTile(
                    title: Text(memo.title.isEmpty ? '无标题' : memo.title),
                    subtitle: Text(memo.content.isEmpty ? '空' : memo.content.substring(0, memo.content.length.clamp(0, 50))),
                    trailing: Text(
                      '${memo.updatedAt.month}/${memo.updatedAt.day}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    onTap: () => _edit(memo),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _newMemo(),
        icon: const Icon(Icons.add),
        label: const Text('新建'),
      ),
    );
  }
  
  Future<void> _newMemo() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MemoEditorScreen()),
    );
    if (result == true) _load();
  }
  
  Future<void> _edit(Memo memo) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => MemoEditorScreen(memo: memo)),
    );
    if (result == true) _load();
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.note_alt_outlined, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text('暂无备忘录', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: 创建 EditorScreen（编辑器）**

```dart
// lib/tools/memo_pad/screen/editor_screen.dart
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../../shared/widgets/common_app_bar.dart';
import '../models/memo.dart';
import '../services/memo_service.dart';

class MemoEditorScreen extends StatefulWidget {
  final Memo? memo;
  const MemoEditorScreen({super.key, this.memo});
  
  @override
  State<MemoEditorScreen> createState() => _MemoEditorScreenState();
}

class _MemoEditorScreenState extends State<MemoEditorScreen> {
  late final _titleCtrl = TextEditingController(text: widget.memo?.title ?? '');
  late final _contentCtrl = TextEditingController(text: widget.memo?.content ?? '');
  bool _saving = false;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(title: widget.memo == null ? '新建备忘录' : '编辑备忘录'),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Title
              TextField(
                controller: _titleCtrl,
                decoration: const InputDecoration(
                  labelText: '标题',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const Divider(height: 16),
              // Content
              Expanded(
                child: TextField(
                  controller: _contentCtrl,
                  decoration: const InputDecoration(
                    hintText: '写下你想记录的...',
                    border: InputBorder.none,
                  ),
                  maxLines: null,
                  expands: true,
                ),
              ),
              const SizedBox(height: 16),
              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (widget.memo != null)
                    TextButton(
                      onPressed: () => _delete(),
                      child: const Text('删除', style: TextStyle(color: Colors.red)),
                    ),
                  SizedBox(
                    width: 100,
                    child: ElevatedButton(
                      onPressed: _saving ? null : _save,
                      child: _saving
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('保存'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final service = MemoService();
      await service.save(Memo(
        id: widget.memo?.id ?? const Uuid().v4(),
        title: _titleCtrl.text.trim(),
        content: _contentCtrl.text.trim(),
        updatedAt: widget.memo?.updatedAt,
      ));
      if (mounted) Navigator.pop(context, true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
  
  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('删除备忘录？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('取消')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('删除')),
        ],
      ),
    );
    if (confirmed == true) {
      final service = MemoService();
      await service.delete(widget.memo!.id);
      if (mounted) Navigator.pop(context, true);
    }
  }
  
  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }
}
```

- [ ] **Step 5: 更新路由 + 验证 Commit**

```dart
// route_registry.dart
import '../tools/memo_pad/screen/list_screen.dart';

// In routes map:
'memo': (context) => const MemoListScreen(),
```

```bash
git add lib/tools/memo_pad/ lib/bottom_nav_bar/route_registry.dart
git commit -m "feat: add memo pad tool (薄望录)"
```

---

### Task 10: 实现番茄钟 + 集成收尾

**Files:**
- Create: `lib/tools/pomodoro_timer/pomodoro_screen.dart` — 番茄钟主页面
- Create: `lib/tools/pomodoro_timer/widgets/timer_ring.dart` — 圆形进度条
- Modify: `lib/bottom_nav_bar/route_registry.dart` — 添加 pomodoro 路由
- Modify: `lib/pages/home_page.dart` — 添加工具路由映射
- Modify: `lib/pages/tools_page.dart` — 添加工具路由映射
- Modify: `pubspec.yaml` — 如需 uuid 则最终确认

**Interfaces:**
- Consumes:
  - `CommonAppBar`
  - Settings 中的番茄时长配置（当前用默认值 25/5）
- Produces:
  - `PomodoroScreen` — 倒计时 + 控制按钮

- [ ] **Step 1: 创建 TimerRing 组件**

```dart
// lib/tools/pomodoro_timer/widgets/timer_ring.dart
import 'package:flutter/material.dart';

class TimerRing extends StatelessWidget {
  final double progress; // 0..1
  final String timeDisplay;
  final bool isRest;
  final double size;
  
  const TimerRing({
    super.key,
    required this.progress,
    required this.timeDisplay,
    this.isRest = false,
    this.size = 240,
  });
  
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background ring
          CustomPaint(
            size: Size(size, size),
            painter: _RingPainter(progress: 0, strokeWidth: 12, color: Colors.grey.shade300),
          ),
          // Progress ring
          CustomPaint(
            size: Size(size, size),
            painter: _RingPainter(
              progress: progress,
              strokeWidth: 12,
              color: isRest ? Colors.green.shade400 : Theme.of(context).colorScheme.primary,
            ),
          ),
          // Time text
          Text(
            timeDisplay,
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  letterSpacing: -2,
                ),
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final double strokeWidth;
  final Color color;
  
  _RingPainter({required this.progress, required this.strokeWidth, required this.color});
  
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    
    if (progress > 0) {
      canvas.drawArc(
        rect,
        -math.pi / 2,
        math.pi * 2 * progress,
        false,
        paint,
      );
    }
  }
  
  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) => progress != oldDelegate.progress;
}
```

> 需要在文件顶部加 `import 'dart:math' as math;`

- [ ] **Step 2: 创建 PomodoroScreen**

```dart
// lib/tools/pomodoro_timer/pomodoro_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import '../../../shared/widgets/common_app_bar.dart';
import 'widgets/timer_ring.dart';

class PomodoroScreen extends StatefulWidget {
  const PomodoroScreen({super.key});
  
  @override
  State<PomodoroScreen> createState() => _PomodoroScreenState();
}

class _PomodoroScreenState extends State<PomodoroScreen> with WidgetsBindingObserver {
  int _workMinutes = 25;
  int _restMinutes = 5;
  int _totalSeconds = 25 * 60;
  int _remainingSeconds = 25 * 60;
  bool _isRunning = false;
  bool _isRest = false; // false = work, true = rest
  int _completedPomodoros = 0;
  Timer? _timer;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // TODO: load preferences from settings/Hive
  }
  
  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
  
  void _start() {
    setState(() => _isRunning = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_remainingSeconds <= 1) {
        _complete();
        t.cancel();
      } else {
        setState(() => _remainingSeconds--);
      }
    });
  }
  
  void _pause() {
    _timer?.cancel();
    setState(() => _isRunning = false);
  }
  
  void _reset() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      _remainingSeconds = _isRest ? _restMinutes * 60 : _workMinutes * 60;
    });
  }
  
  void _complete() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      if (!_isRest) {
        _completedPomodoros++;
      }
      _switchPhase();
    });
    
    // Vibrate on completion
    // TODO: vibration plugin, or just leave it
    
    // Show dialog
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          title: Text(_isRest ? '休息结束！' : '番茄完成！🍅'),
          content: Text(_isRest ? '继续专注吧！' : '休息一下~'),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() => _isRunning = true);
                _timer = Timer.periodic(const Duration(seconds: 1), (t) {
                  if (_remainingSeconds <= 1) {
                    _complete();
                    t.cancel();
                  } else {
                    setState(() => _remainingSeconds--);
                  }
                });
              },
              child: const Text('开始'),
            ),
          ],
        ),
      );
    }
  }
  
  void _switchPhase() {
    setState(() {
      _isRest = !_isRest;
      _remainingSeconds = _isRest ? _restMinutes * 60 : _workMinutes * 60;
    });
  }
  
  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
  
  @override
  Widget build(BuildContext context) {
    final total = _isRest ? _restMinutes * 60 : _workMinutes * 60;
    final progress = total > 0 ? _remainingSeconds / total : 0;
    
    return Scaffold(
      appBar: CommonAppBar(
        title: '番茄钟',
        actions: [
          Text(
            '🍅 $_completedPomodoros',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Timer display
            TimerRing(
              progress: progress,
              timeDisplay: _formatTime(_remainingSeconds),
              isRest: _isRest,
            ),
            const SizedBox(height: 24),
            
            // Phase label
            Text(
              _isRest ? '休息时间' : '专注时间',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 48),
            
            // Controls
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Reset
                _controlButton(
                  icon: Icons.restart_alt,
                  label: '重置',
                  onPressed: _reset,
                ),
                const SizedBox(width: 24),
                // Start/Pause
                SizedBox(
                  width: 72,
                  height: 72,
                  child: ElevatedButton(
                    onPressed: _isRunning ? _pause : _start,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isRunning
                          ? Theme.of(context).colorScheme.secondaryContainer
                          : Theme.of(context).colorScheme.primary,
                    ),
                    child: Icon(
                      _isRunning ? Icons.pause : Icons.play_arrow,
                      size: 32,
                      color: _isRunning
                          ? Theme.of(context).colorScheme.onSecondaryContainer
                          : Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

Widget _controlButton({required IconData icon, required String label, required VoidCallback onPressed}) {
  return OutlinedButton(
    onPressed: onPressed,
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18),
        const SizedBox(width: 4),
        Text(label),
      ],
    ),
  );
}
```

- [ ] **Step 3: 更新路由注册 + 完善所有页面的 onTap 跳转**

```dart
// route_registry.dart
import '../tools/pomodoro_timer/pomodoro_screen.dart';

// Add to routes map:
'pomodoro': (context) => const PomodoroScreen(),
```

并在 `home_page.dart` 和 `tools_page.dart` 的 `_onToolTap` 中补全所有路由映射：

```dart
static const _routeMap = {
  'qr': 'qr',         // 二维码生成器
  'ai_chat': 'ai_chat', // 有机交流电灯
  'expense': 'expense', // 寄丢记账
  'memo': 'memo',     // 薄望录
  'pomodoro': 'pomodoro', // 番茄钟
};

void _navigate(String toolKey) {
  final route = _routeMap[toolKey];
  if (route != null) {
    Navigator.pushNamed(context, route);
  }
}
```

- [ ] **Step 4: 全局测试 & 最终验证**

逐项测试所有功能：
1. ✅ 底部导航栏 3 Tab 切换流畅
2. ✅ 首页 5 个工具卡片均可点击进入对应页面
3. ✅ QR 生成器输入文字 → 生成二维码
4. ✅ 有机交流电灯输入消息 → 收到回复（或错误提示）
5. ✅ 寄丢记账录入 → 列表显示 → 删除 → 汇总
6. ✅ 薄望录新建 → 编辑 → 删除
7. ✅ 番茄钟开始 → 倒计时 → 完成提醒
8. ✅ 设置页各项选项可交互
9. ✅ 深色/浅色模式自动切换正确
10. ✅ 返回按钮逐级返回

- [ ] **Step 5: Commit**

```bash
git add lib/tools/pomodoro_timer/ lib/pages/*.dart lib/bottom_nav_bar/route_registry.dart
git commit -m "feat: add pomodoro timer and complete all tool integrations"
```

---

## 里程碑检查点

| 完成阶段 | 可交付物 |
|---------|---------|
| Task 2 结束 | 项目可运行，含 Theme + Hive + 共享组件 |
| Task 5 结束 | 框架完整可用（底部导航 + 3 Tab 页面骨架）|
| Task 6 结束 | 第一个工具上线，端到端跑通 |
| Task 7 结束 | AI 对话可用（需真实 API Key）|
| Task 8 结束 | 记账功能闭环 |
| Task 9 结束 | 所有 5 个工具均实现 |
| Task 10 结束 | 全量测试 + 集成收尾 |
