# 寄丢工具箱 🧰

一个基于 Flutter 开发的 Android 工具箱 App，集实用工具与小游戏于一体。

## ✨ 功能特性

### 🔧 工具箱

| 工具 | 说明 |
|------|------|
| 二维码生成器 | 输入文本/链接，即时生成二维码并分享 |
| 寄丢记账 | 记录收支明细，数据本地持久化存储（Hive） |
| 薄望录 | 简洁的备忘录，支持增删查改 |
| 番茄钟 | 经典番茄工作法计时器（25 分钟工作 / 5 分钟休息），自定义时长 |

### 🎮 小游戏

| 游戏 | 说明 |
|------|------|
| 数字华容道 | 滑动拼图，支持 3×3 / 4×4 / 5×5 三种难度，正确位置自动高亮提示 |
| 俄罗斯方块 | 经典方块消除，网格线分隔，触屏手势操控，支持旋转和硬降 |
| 贪吃蛇 | 控制方向吃食物，触屏滑动操控 |

**深色模式** — 切换系统主题即可在明暗两种风格间无缝切换。  
**离线可用** — 所有数据存储在本地，无需联网。

<img width="1920" height="1337" alt="a2adeaa3ddafcc9e3c5743516ee9fe8a" src="https://github.com/user-attachments/assets/1bb6f865-73f4-4b74-b0cb-cb82a7b21c7c" />

> - 首页：四个工具卡片排列
> - 小游戏页：数字华容道 / 俄罗斯方块 / 贪吃蛇列表
> - 设置页：深色主题开关、番茄钟时长配置

## 🛠️ 技术栈

| 组件 | 技术 |
|------|------|
| 框架 | [Flutter](https://flutter.dev) 3.x |
| 语言 | Dart 3.x |
| 本地数据库 | [Hive](https://docs.hivesql.dev) + Hive Flutter |
| 状态管理 | `ChangeNotifier` + `WidgetsBindingObserver` |
| 构建目标 | Android APK |

## 📁 项目结构

```
lib/
├── main.dart                         # 应用入口 & 主题订阅
├── bottom_nav_bar/
│   ├── container.dart                # 底部导航栏（首页/游戏/设置）
│   ├── navigation_state.dart         # 导航状态保持
│   └── route_registry.dart           # 路由注册表
├── pages/
│   ├── home_page.dart                # 首页（快捷入口卡片）
│   ├── game_hub.dart                 # 小游戏合集
│   ├── settings_page.dart            # 设置页
│   └── tools_page.dart               # 工具详情页
├── games/
│   ├── sliding_puzzle.dart           # 数字华容道
│   ├── tetris_game.dart              # 俄罗斯方块
│   └── snake_game.dart               # 贪吃蛇
├── shared/
│   ├── constants.dart                # 全局常量
│   ├── app_settings.dart             # 主题设置单例
│   ├── hive/
│   │   └── hive_init.dart            # Hive 初始化 & Box 注册
│   ├── theme/
│   │   ├── app_theme.dart            # 主题基类
│   │   ├── light_theme.dart          # 浅色主题
│   │   └── dark_theme.dart           # 深色主题
│   └── widgets/
│       ├── common_app_bar.dart       # 通用 AppBar
│       ├── grid_cell.dart            # 网格单元格
│       └── tool_card.dart            # 工具卡片
└── tools/
    ├── qr_code_generator/            # 二维码生成器
    ├── expense_tracker/              # 寄丢记账
    ├── memo_pad/                     # 薄望录
    ├── pomodoro_timer/               # 番茄钟
    └── ai_chat/                      # AI 聊天（待接入记账功能中）
```


## ⚙️ 数据持久化

项目使用 [Hive](https://docs.hivesql.dev) 进行本地数据存储：

- **expenses** — 记账条目（金额、分类、日期、备注）
- **memos** — 备忘录（标题、内容、创建时间）
- **settings** — 用户偏好（主题亮度、番茄钟时长等）

所有数据保存在设备本地，卸载 App 即清除。

## 📄 License

MIT
