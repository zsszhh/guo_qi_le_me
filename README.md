# 过期了么 - AI智能物品保质期管理应用

![Flutter](https://img.shields.io/badge/Flutter-3.11.5-blue)
![Dart](https://img.shields.io/badge/Dart-3.11.5-blue)
![License](https://img.shields.io/badge/License-MIT-green)

一款基于 AI 的智能物品保质期管理应用，帮助用户轻松管理家中物品，减少食物浪费。

## ✨ 功能特性

### 🤖 AI 智能功能
- **AI 图像识别**：拍照识别物品，自动获取保质期信息
- **AI 语音输入**：支持语音添加物品，解放双手
- **智能分析**：基于消费习惯提供个性化建议

### 📦 物品管理
- 物品录入与分类管理
- 保质期自动计算与提醒
- 部分消费记录支持
- 物品状态追踪（正常/即将过期/已过期）

### 🔔 提醒系统
- 自定义提醒时间
- 过期前智能提醒
- 提醒日志记录

### ☁️ 数据备份
- WebDAV 远程备份
- 本地数据导出
- 自动备份策略

### 📱 多平台支持
- Android
- iOS
- Windows
- macOS
- Linux

## 🛠️ 技术栈

| 分类 | 技术 | 版本 |
| :--- | :--- | :--- |
| 框架 | Flutter | ^3.11.5 |
| 语言 | Dart | ^3.11.5 |
| 状态管理 | Riverpod | ^3.3.1 |
| 数据库 | SQLite (sqflite) | ^2.4.2 |
| 语音识别 | speech_to_text | ^7.0.0 |
| 推送通知 | flutter_local_notifications | ^21.0.0 |
| HTTP 客户端 | Dio | ^5.8.0+1 |
| WebDAV | webdav_client | ^1.2.2 |

## 🚀 快速开始

### 环境要求

- Flutter 3.11.5+
- Dart 3.11.5+
- Android Studio / Xcode（根据目标平台）

### 安装依赖

```bash
cd food_app
flutter pub get
```

### 运行项目

```bash
# 运行调试模式
flutter run

# 构建 APK（Android）
flutter build apk

# 构建 IPA（iOS）
flutter build ios

# 构建 Windows 应用
flutter build windows

# 构建 macOS 应用
flutter build macos

# 构建 Linux 应用
flutter build linux
```

## 📁 项目结构

```
lib/
├── data/                 # 数据层
│   └── expiry_rules.dart # 过期规则
├── models/               # 数据模型
│   ├── item.dart         # 物品模型
│   ├── ai_config.dart    # AI 配置
│   └── ...
├── pages/                # 页面组件
│   ├── home_page.dart    # 首页
│   ├── ai_input_page.dart # AI 输入页
│   └── ...
├── providers/            # 状态管理
│   ├── item_provider.dart
│   └── ...
├── services/             # 服务层
│   ├── ai_service.dart   # AI 服务
│   ├── backup_service.dart # 备份服务
│   └── ...
├── theme/                # 主题配置
├── utils/                # 工具类
├── widgets/              # 可复用组件
├── app.dart              # 应用入口
└── main.dart             # 主函数
```

## 🤝 贡献指南

欢迎贡献代码！请遵循以下步骤：

1. Fork 本仓库
2. 创建特性分支：`git checkout -b feature/your-feature`
3. 提交更改：`git commit -m 'Add some feature'`
4. 推送到分支：`git push origin feature/your-feature`
5. 创建 Pull Request

## 📄 许可证

本项目采用 MIT 许可证 - 查看 [LICENSE](LICENSE) 文件了解详情。

## 📧 联系方式

如有问题或建议，欢迎提交 Issue 或发送邮件。

---

**减少食物浪费，从管理保质期开始！** 🥗✨