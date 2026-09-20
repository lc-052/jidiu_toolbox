# 寄丢工具箱 — Design Spec

## 概述

面向 Android 的实用工具箱 App，将 5 个常用小工具集中到一个应用中。
MD3 风格，支持深色/浅色模式，适配不同屏幕尺寸。

## 项目信息

| 项 | 值 |
|---|---|
| 名称 | 寄丢工具箱 |
| 框架 | Flutter + Dart |
| 平台 | Android |
| UI | Material Design 3 |
| 存储 | Hive（本地 NoSQL） |
| 状态管理 | StatefulWidget + setState（最简） |
| 依赖数 | 核心 4 个包 |

## 核心依赖

| 包 | 用途 |
|---|---|
| `hive` + `hive_flutter` | 本地数据存储 |
| `path_provider` | Hive 文件路径 |
| `qr_flutter` | QR 码渲染显示 |
| `http` | AI 对话 HTTP 请求 |

## 应用结构

```
lib/
├── main.dart                  # 入口，初始化 Hive、Theme、路由
├── app.dart                   # MaterialApp 配置
│
├── shared/                    # 共享层
│   ├── theme/
│   │   ├── light_theme.dart
│   │   └── dark_theme.dart
│   ├── hive/
│   │   ├── adapter.g.dart     # Hive 生成代码
│   │   └── hive_init.dart     # Hive 初始化 + Box 获取
│   ├── widgets/
│   │   ├── common_app_bar.dart
│   │   ├── empty_state.dart
│   │   └── tool_card.dart
│   └── constants.dart
│
├── tools/                     # 每个工具独立模块
│   ├── qr_code_generator/
│   │   ├── qr_screen.dart
│   │   └── widgets/
│   ├── ai_chat/
│   │   ├── chat_screen.dart
│   │   ├── models/chat_message.dart
│   │   └── services/api_client.dart
│   ├── expense_tracker/
│   │   ├── screen/entry_screen.dart
│   │   ├── screen/list_screen.dart
│   │   ├── models/expense.dart
│   │   └── services/expense_service.dart
│   ├── memo_pad/
│   │   ├── screen/editor_screen.dart
│   │   ├── screen/list_screen.dart
│   │   ├── models/memo.dart
│   │   └── services/memo_service.dart
│   └── pomodoro_timer/
│       ├── pomodoro_screen.dart
│       └── widgets/
│
├── bottom_nav_bar/            # 底部导航栏
└── pages/                     # 三大 Tab 页
    ├── home_page.dart
    ├── tools_page.dart
    └── settings_page.dart
```

## 数据模型 (Hive)

### Expense（记账条目）
- `id: String`（UUID）
- `amount: double`
- `type: Enum {income, expense}`
- `category: String`（可选分类：餐饮/交通/娱乐/工资/其他）
- `note: String`
- `createdAt: DateTime`

### Memo（备忘录）
- `id: String`（UUID）
- `title: String`
- `content: String`
- `updatedAt: DateTime`

### ChatHistory（聊天记录）— 内存中维护，也可持久化
- `messages: List<ChatMessage>`
- `role: Enum {system, user, assistant}`
- `content: String`

## 页面设计

### 首页 Home Page

```
AppBar: 「寄丢工具箱」
Body:
  Welcome section: 欢迎语 + 简短介绍
  
  📱 常用工具
  ┌─────────────────────┐
  │  ┌───────────┬─────┐│
  │  │ 二维码生成器│ 番  ││
  │  │           │ 茄  ││
  │  └───────────┴─────┘│
  │  ┌───────────┬─────┐│
  │  │  寄丢记账   │ 有  ││
  │  │           │ 机  ││
  │  └───────────┴─────┘│
  │  ┌─────────────────┐│
  │  │   薄望录          ││
  │  │                 ││
  │  └─────────────────┘│
  └─────────────────────┘
```

布局逻辑：右上放番茄钟卡片，右下放电灯卡片，单独一行放薄望录大卡。

### 工具页 Tools Page

```
AppBar: 「工具」
Body: 2 列网格
┌──────┬──────┐
│ 二维码│ 番茄钟 │
├──────┼──────┤
│ 记账  │  电灯  │
├──────┼──────┤
│ 薄望录│ 🔒预留 │
└──────┴──────┘
```

### 设置页 Settings Page

```
AppBar: 「设置」
Body:
  ▸ 外观设置
    ○ 跟随系统  ● 浅色  ○ 深色
  ▸ AI 聊天设置
    API Key: [________________]
    Base URL: [https://api.openai.com/v1]
  ▸ 番茄钟设置
    工作时长: [25] min
    休息时长: [5] min
  ▸ 关于
    寄丢工具箱 v0.1.0
```

### 工具详情页面

#### 1. 二维码生成器
- TextField 输入文字/链接
- 大尺寸 QR 码展示区
- "复制" + "保存为图片"按钮

#### 2. 有机交流电灯
- 类似聊天界面的消息列表
- 顶部可收起的「API 配置面板」
- 底部消息输入框 + 发送按钮
- 流式 SRE/SSE 响应（打字机效果）
- 错误处理：超时 → 提示重试；无效 Key → 提示检查

#### 3. 寄丢记账
- **列表页**：按日期分组的收支列表
  - 悬浮 FAB 添加新条目
  - 顶部汇总卡片（本月收入/支出/结余）
- **录入页**：金额输入 / 类型选择 / 分类选择 / 备注

#### 4. 薄望录
- **列表页**：标题 + 摘要预览 + 更新时间
- **编辑页**：标题输入 / 正文多行文本
  - 支持 Markdown 纯文本（暂不富文本）

#### 5. 番茄钟
- 大号圆形进度条显示倒计时
- 当前阶段标签（工作/休息）
- 开始 / 暂停 / 重置按钮
- 完成时振动提醒（或播放短提示音）
- 已完成的番茄数量计数器

## 导航策略

- Scaffold + BottomNavigationBar（3 Tab）
- 点击工具卡片 → Navigator.push() 进入详情页
- 详情页 AppBar 自带返回按钮 → pop() 回到对应 Tab

## AI 对话 API 设计

```dart
// OpenAI 兼容端点
POST /v1/chat/completions
Headers: Authorization: Bearer <api_key>
Body:
{
  "model": "default-model-name",
  "messages": [
    {"role": "system", "content": "你是一个..."},
    {"role": "user", "content": "你好"},
    {"role": "assistant", "content": "..."}
  ],
  "stream": true  // or false
}
Response (stream):
data: {"choices":[{"delta":{"content":"Hello"}}]}

data: [DONE]
```

## 主题设计

- 浅色背景: Color(0xFFF8F9FA)
- 深色背景: Color(0xFF121212)  
- 主色: Material primary color（可定制占位）
- 图标填充颜色随主题自动切换
