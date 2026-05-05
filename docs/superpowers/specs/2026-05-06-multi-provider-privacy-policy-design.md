# 多AI提供商支持 + 隐私政策页面设计

**日期**: 2026-05-06  
**状态**: 待审查

---

## 概述

本设计包含两个独立功能：

1. **多AI提供商支持** - 允许用户配置多个AI服务提供商，设置默认配置，实现快速切换
2. **隐私政策页面** - 在设置页面新增完整的隐私政策独立页面

同时调整设置页面，移除"帮助与反馈"入口。

---

## 功能一：多AI提供商支持

### 1.1 用户故事

> 作为用户，我希望能够配置多个AI服务提供商，当某一个服务不可用时可以快速切换到备用提供商，避免影响正常使用。

### 1.2 功能需求

| 需求 | 描述 |
|------|------|
| FR-1.1 | 用户可添加多个AI提供商配置 |
| FR-1.2 | 每个配置包含：名称、API地址、API Key、默认模型、超时设置、启用状态 |
| FR-1.3 | 用户可设置其中一个配置为"默认" |
| FR-1.4 | 系统调用AI服务时自动使用默认配置 |
| FR-1.5 | 用户可快速切换默认配置（无需进入编辑页） |
| FR-1.6 | 用户可删除、复制配置 |
| FR-1.7 | 预设提供商（豆包）不可删除，但可编辑 |

### 1.3 数据模型变更

#### AIProvider 枚举调整

```dart
enum AIProvider {
  doubao('豆包', isPreset: true),    // 预设，不可删除
  custom('自定义', isPreset: false); // 用户自定义
}
```

保持不变，通过 `isPreset` 区分预设和自定义。

#### AIConfig 模型新增字段

```dart
class AIConfig {
  final String id;
  final AIProvider provider;
  final String apiKey;
  final String defaultModel;
  final String? baseUrl;
  final String? displayName;      // 用户自定义名称
  final int timeoutSeconds;
  final bool enabled;
  final bool isDefault;           // 新增：是否为默认配置
  final DateTime createdAt;
  final DateTime updatedAt;
}
```

#### 数据库迁移

- 版本: 4
- 变更: `ai_configs` 表新增 `is_default INTEGER DEFAULT 0` 字段

### 1.4 数据库服务扩展

| 方法 | 描述 |
|------|------|
| `Future<List<AIConfig>> getAllAIConfigs()` | 获取所有配置列表 |
| `Future<AIConfig?> getAIConfig()` | 获取默认配置（is_default=1） |
| `Future<void> saveAIConfig(AIConfig)` | 保存配置（新增或更新） |
| `Future<void> deleteAIConfig(String id)` | 删除配置（预设不可删） |
| `Future<void> setDefaultAIConfig(String id)` | 设置默认配置 |
| `Future<void> duplicateAIConfig(String id)` | 复制配置 |

### 1.5 UI结构

#### 页面层级

```
设置页
  └─ AI服务配置 → AI配置列表页 (AIConfigListPage)
                    ├─ 添加新配置按钮
                    ├─ 配置卡片列表
                    │   ├─ 配置名称 + 提供商类型
                    │   ├─ 状态标识（默认/已启用/已禁用）
                    │   └─ 操作：设为默认/编辑/删除/复制
                    └─ 点击配置 → AI配置编辑页 (AIConfigEditPage)
                                    ├─ 提供商选择
                                    ├─ API配置表单
                                    └─ 测试连接
```

#### AIConfigListPage 功能

- 顶部显示当前默认配置概览
- 列表展示所有配置，默认配置置顶并高亮
- 每个配置卡片：
  - 显示名称、提供商类型、模型
  - 状态徽章：默认(金色)、启用(绿色)、禁用(灰色)
  - 快捷操作：设为默认按钮、更多操作菜单（编辑/复制/删除）
- 底部浮动按钮：添加新配置

#### AIConfigEditPage 功能

- 基于现有 `AIConfigPage` 改造
- 支持新建和编辑两种模式
- 编辑预设提供商时，隐藏删除按钮

### 1.6 状态管理

```dart
/// AI配置列表状态
class AIConfigListState {
  final List<AIConfig> configs;
  final String? defaultConfigId;
  final bool isLoading;
  final String? error;
}

/// Provider
final aiConfigListProvider = StateNotifierProvider<AIConfigListNotifier, AIConfigListState>(...);
```

### 1.7 业务规则

| 规则 | 描述 |
|------|------|
| BR-1 | 至少保留一个启用的配置作为默认 |
| BR-2 | 删除配置时，若为默认则自动将第一个启用的配置设为默认 |
| BR-3 | 预设提供商（豆包）配置不可删除，但可禁用 |
| BR-4 | 切换默认配置时立即生效，无需重启应用 |
| BR-5 | API Key 使用 flutter_secure_storage 加密存储 |

### 1.8 错误处理

| 场景 | 处理方式 |
|------|----------|
| 所有配置都被禁用 | AI功能入口提示"请先启用至少一个AI配置" |
| 默认配置连接失败 | 弹出提示，引导用户检查配置或切换默认 |
| 无任何配置 | 显示空状态，引导用户添加配置 |

---

## 功能二：隐私政策页面

### 2.1 用户故事

> 作为用户，我希望了解应用如何处理我的数据，包括本地存储、AI服务调用和云同步相关的隐私信息。

### 2.2 功能需求

| 需求 | 描述 |
|------|------|
| FR-2.1 | 从设置页"关于"卡片进入隐私政策页面 |
| FR-2.2 | 页面展示完整的隐私政策内容 |
| FR-2.3 | 内容包含：数据收集、存储方式、第三方服务、用户权利等 |

### 2.3 页面结构

```
PrivacyPolicyPage
├─ AppBar: "隐私政策"
└─ SingleChildScrollView
    ├─ 更新日期
    ├─ 引言
    ├─ 1. 信息收集与使用
    ├─ 2. 信息存储
    ├─ 3. 第三方服务
    │   ├─ 3.1 AI服务
    │   └─ 3.2 WebDAV同步服务
    ├─ 4. 信息共享
    ├─ 5. 信息安全
    ├─ 6. 用户权利
    ├─ 7. 未成年人保护
    ├─ 8. 政策更新
    └─ 9. 联系我们
```

### 2.4 隐私政策内容要点

#### 1. 信息收集与使用
- 用户主动输入的物品信息（名称、分类、保质期等）
- 用户配置的AI服务API Key（加密存储于本地）
- 用户配置的WebDAV服务器信息

#### 2. 信息存储
- 所有数据存储于用户设备本地SQLite数据库
- API Key使用系统密钥库加密存储
- 不上传至任何中央服务器

#### 3. 第三方服务
- **AI服务**：用户自行选择并配置的AI提供商，应用仅调用其API进行物品识别，图片和识别请求发送至用户配置的AI服务端点
- **WebDAV同步**：用户自行配置的WebDAV服务器，用于数据备份与同步

#### 4. 信息共享
- 不向任何第三方出售或共享用户数据
- 仅在用户主动配置并启用同步功能时，将数据传输至用户指定的WebDAV服务器

#### 5. 信息安全
- 本地数据库加密
- 敏感信息（API Key）使用系统级加密存储
- 网络传输使用HTTPS

#### 6. 用户权利
- 查看、修改、删除所有个人数据
- 导出数据备份
- 随时禁用AI功能和同步功能
- 卸载应用将清除所有本地数据

#### 7. 未成年人保护
- 面向所有年龄段用户
- 不收集任何个人信息

#### 8. 政策更新
- 更新将在应用内通知用户
- 重大变更需用户确认

#### 9. 联系我们
- 提供开发者联系方式

### 2.5 实现方式

- 创建 `lib/pages/privacy_policy_page.dart`
- 使用 `SingleChildScrollView` + 多个 `Text` 和 `Padding` Widget 构建
- 内容直接硬编码在代码中（便于版本控制和追踪变更）

---

## 功能三：设置页面调整

### 3.1 变更内容

| 变更 | 描述 |
|------|------|
| 删除 | 移除"帮助与反馈"设置项 |
| 保留 | 保留"隐私政策"设置项，跳转至新页面 |
| 跳转修改 | AI服务配置跳转至新的 `AIConfigListPage` |

### 3.2 调整后的"关于"卡片结构

```
关于
├─ 关于应用
└─ 隐私政策
```

---

## 技术影响评估

### 影响范围

| 文件 | 变更类型 | 描述 |
|------|----------|------|
| `lib/models/ai_config.dart` | 修改 | 新增 `isDefault` 字段 |
| `lib/services/database_service.dart` | 修改 | 数据库迁移 + 新增CRUD方法 |
| `lib/pages/ai_config_page.dart` | 重构 | 改为编辑页，供列表页调用 |
| `lib/pages/ai_config_list_page.dart` | 新增 | 配置列表页 |
| `lib/pages/settings_page.dart` | 修改 | 调整跳转 + 移除帮助反馈 |
| `lib/pages/privacy_policy_page.dart` | 新增 | 隐私政策页面 |
| `lib/services/ai_service.dart` | 修改 | 使用默认配置获取逻辑 |
| `lib/providers/*` | 新增/修改 | 配置列表状态管理 |

### 数据库迁移

```dart
// 版本 3 → 4
await db.execute('ALTER TABLE ai_configs ADD COLUMN is_default INTEGER DEFAULT 0');
```

### 兼容性

- 现有配置自动设为默认配置（is_default=1）
- 现有功能入口（AI输入页）无需修改，自动使用默认配置

---

## 实现优先级

| 优先级 | 功能 | 原因 |
|--------|------|------|
| P0 | 数据库迁移 + 模型修改 | 基础依赖 |
| P0 | 数据库服务扩展 | 基础依赖 |
| P1 | AI配置列表页 | 核心功能 |
| P1 | AI配置编辑页改造 | 核心功能 |
| P2 | 设置页面调整 | 集成入口 |
| P2 | 隐私政策页面 | 独立功能 |

---

## 测试要点

### 多提供商功能

- [ ] 添加多个配置，验证列表正确显示
- [ ] 设置默认配置，验证AI调用使用正确配置
- [ ] 删除非默认配置，验证其他配置不受影响
- [ ] 删除默认配置，验证自动切换默认
- [ ] 禁用所有配置，验证AI功能提示正确
- [ ] 复制配置，验证生成新配置且API Key正确复制

### 隐私政策页面

- [ ] 页面完整显示，滚动正常
- [ ] 内容涵盖所有必要条款
- [ ] 从设置页正确跳转

### 设置页面

- [ ] 帮助与反馈入口已移除
- [ ] 隐私政策入口正确跳转
- [ ] AI配置入口跳转至列表页
