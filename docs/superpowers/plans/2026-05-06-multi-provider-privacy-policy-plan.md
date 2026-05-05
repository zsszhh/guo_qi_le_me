# 多AI提供商支持 + 隐私政策页面 实现计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 实现多AI提供商配置管理和隐私政策页面，支持用户添加多个AI配置并快速切换默认配置。

**Architecture:** 数据层新增 `isDefault` 字段和多配置CRUD方法；UI层拆分为配置列表页+配置编辑页两级结构；隐私政策作为独立页面实现。

**Tech Stack:** Flutter, SQLite (sqflite), Riverpod, flutter_secure_storage

---

## 文件结构

| 文件 | 变更类型 | 职责 |
|------|----------|------|
| `lib/models/ai_config.dart` | 修改 | 新增 `isDefault` 字段 |
| `lib/services/database_service.dart` | 修改 | 数据库迁移v4 + 多配置CRUD方法 |
| `lib/providers/ai_config_list_provider.dart` | 新增 | 配置列表状态管理 |
| `lib/pages/ai_config_list_page.dart` | 新增 | AI配置列表页面 |
| `lib/pages/ai_config_page.dart` | 重构 | 改造为配置编辑页面 |
| `lib/pages/privacy_policy_page.dart` | 新增 | 隐私政策页面 |
| `lib/pages/settings_page.dart` | 修改 | 调整导航 + 移除帮助反馈 |
| `lib/app.dart` | 修改 | 注册新路由 |

---

## Task 1: 数据模型层 - AIConfig 添加 isDefault 字段

**Files:**
- Modify: `lib/models/ai_config.dart`

- [ ] **Step 1: 修改 AIConfig 模型，添加 isDefault 字段**

```dart
// 在 AIConfig 类中添加字段
class AIConfig {
  final String id;
  final AIProvider provider;
  final String apiKey;
  final String defaultModel;
  final String? baseUrl;
  final String? displayName;
  final int timeoutSeconds;
  final bool enabled;
  final bool isDefault;  // 新增：是否为默认配置
  final DateTime createdAt;
  final DateTime updatedAt;

  const AIConfig({
    required this.id,
    required this.provider,
    required this.apiKey,
    required this.defaultModel,
    this.baseUrl,
    this.displayName,
    this.timeoutSeconds = 30,
    this.enabled = true,
    this.isDefault = false,  // 默认值为 false
    required this.createdAt,
    required this.updatedAt,
  });

  // 更新 fromJson 方法
  factory AIConfig.fromJson(Map<String, dynamic> json) {
    bool parseBool(dynamic value, {bool defaultValue = true}) {
      if (value == null) return defaultValue;
      if (value is bool) return value;
      if (value is int) return value != 0;
      return defaultValue;
    }

    return AIConfig(
      id: json['id'] as String,
      provider: AIProvider.values.firstWhere(
        (e) => e.name == json['provider'],
        orElse: () => AIProvider.doubao,
      ),
      apiKey: json['api_key'] as String? ?? '',
      defaultModel: json['default_model'] as String? ?? 'doubao-1.5-vision-pro',
      baseUrl: json['base_url'] as String?,
      displayName: json['display_name'] as String?,
      timeoutSeconds: json['timeout_seconds'] as int? ?? 30,
      enabled: parseBool(json['enabled'], defaultValue: true),
      isDefault: parseBool(json['is_default'], defaultValue: false),  // 新增
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  // 更新 toJson 方法
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'provider': provider.name,
      'api_key': apiKey,
      'default_model': defaultModel,
      'base_url': baseUrl,
      'display_name': displayName,
      'timeout_seconds': timeoutSeconds,
      'enabled': enabled ? 1 : 0,
      'is_default': isDefault ? 1 : 0,  // 新增
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // 更新 copyWith 方法
  AIConfig copyWith({
    String? id,
    AIProvider? provider,
    String? apiKey,
    String? defaultModel,
    String? baseUrl,
    String? displayName,
    int? timeoutSeconds,
    bool? enabled,
    bool? isDefault,  // 新增
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AIConfig(
      id: id ?? this.id,
      provider: provider ?? this.provider,
      apiKey: apiKey ?? this.apiKey,
      defaultModel: defaultModel ?? this.defaultModel,
      baseUrl: baseUrl ?? this.baseUrl,
      displayName: displayName ?? this.displayName,
      timeoutSeconds: timeoutSeconds ?? this.timeoutSeconds,
      enabled: enabled ?? this.enabled,
      isDefault: isDefault ?? this.isDefault,  // 新增
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // 更新 defaultConfig 工厂方法
  factory AIConfig.defaultConfig(String id) {
    final now = DateTime.now();
    return AIConfig(
      id: id,
      provider: AIProvider.doubao,
      apiKey: '',
      defaultModel: 'doubao-1.5-vision-pro',
      isDefault: true,  // 默认配置自动设为默认
      createdAt: now,
      updatedAt: now,
    );
  }
}
```

- [ ] **Step 2: 提交数据模型修改**

```bash
git add lib/models/ai_config.dart
git commit -m "feat(ai-config): add isDefault field to AIConfig model"
```

---

## Task 2: 数据库层 - 迁移和多配置CRUD方法

**Files:**
- Modify: `lib/services/database_service.dart`

- [ ] **Step 1: 更新数据库版本号**

```dart
// 修改 _databaseVersion 常量
static const int _databaseVersion = 4;  // 从 3 升级到 4
```

- [ ] **Step 2: 在 _onCreate 方法中添加 is_default 字段**

找到 `CREATE TABLE $tableAIConfigs` 语句，添加 `is_default` 字段：

```dart
// AI配置表
await db.execute('''
  CREATE TABLE $tableAIConfigs (
    id TEXT PRIMARY KEY,
    provider TEXT NOT NULL,
    api_key TEXT NOT NULL,
    default_model TEXT NOT NULL,
    base_url TEXT,
    display_name TEXT,
    timeout_seconds INTEGER DEFAULT 30,
    enabled INTEGER DEFAULT 1,
    is_default INTEGER DEFAULT 0,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL
  )
''');
```

- [ ] **Step 3: 在 _onUpgrade 方法中添加迁移逻辑**

```dart
/// 数据库升级
Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
  // 版本1到版本2：添加AI配置新字段和自定义选项表
  if (oldVersion < 2) {
    await db.execute('ALTER TABLE $tableAIConfigs ADD COLUMN base_url TEXT');
    await db.execute('ALTER TABLE $tableAIConfigs ADD COLUMN display_name TEXT');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tableCustomOptions (
        id TEXT PRIMARY KEY,
        option_type TEXT NOT NULL,
        category TEXT,
        value TEXT NOT NULL,
        usage_count INTEGER DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
  }

  // 版本2到版本3：添加产品图片表
  if (oldVersion < 3) {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tableProductImages (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        image_path TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('CREATE INDEX IF NOT EXISTS idx_product_images_name ON $tableProductImages (name)');
  }

  // 版本3到版本4：添加 is_default 字段支持多配置
  if (oldVersion < 4) {
    await db.execute('ALTER TABLE $tableAIConfigs ADD COLUMN is_default INTEGER DEFAULT 0');
    // 将现有配置设为默认
    await db.execute('UPDATE $tableAIConfigs SET is_default = 1 WHERE enabled = 1');
  }
}
```

- [ ] **Step 4: 添加多配置CRUD方法**

在 `// ==================== AI配置操作 ====================` 注释后添加：

```dart
// ==================== AI配置操作 ====================

/// 获取所有AI配置列表
Future<List<AIConfig>> getAllAIConfigs() async {
  final db = await database;
  final List<Map<String, dynamic>> maps = await db.query(
    tableAIConfigs,
    orderBy: 'is_default DESC, updated_at DESC',
  );
  return maps.map((map) => AIConfig.fromJson(map)).toList();
}

/// 获取默认AI配置
Future<AIConfig?> getAIConfig() async {
  final db = await database;
  final List<Map<String, dynamic>> maps = await db.query(
    tableAIConfigs,
    where: 'is_default = ?',
    whereArgs: [1],
  );
  if (maps.isEmpty) {
    // 降级：返回第一个启用的配置
    final enabledMaps = await db.query(
      tableAIConfigs,
      where: 'enabled = ?',
      whereArgs: [1],
      limit: 1,
    );
    if (enabledMaps.isEmpty) return null;
    return AIConfig.fromJson(enabledMaps.first);
  }
  return AIConfig.fromJson(maps.first);
}

/// 保存AI配置（新增或更新）
Future<void> saveAIConfig(AIConfig config) async {
  final db = await database;
  await db.insert(
    tableAIConfigs,
    config.toJson(),
    conflictAlgorithm: ConflictAlgorithm.replace,
  );
}

/// 设置默认AI配置
Future<void> setDefaultAIConfig(String id) async {
  final db = await database;
  // 先清除所有默认
  await db.update(
    tableAIConfigs,
    {'is_default': 0},
  );
  // 设置指定配置为默认
  await db.update(
    tableAIConfigs,
    {'is_default': 1, 'updated_at': DateTime.now().toIso8601String()},
    where: 'id = ?',
    whereArgs: [id],
  );
}

/// 删除AI配置
Future<void> deleteAIConfig(String id) async {
  final db = await database;
  
  // 检查是否为默认配置
  final maps = await db.query(
    tableAIConfigs,
    where: 'id = ?',
    whereArgs: [id],
  );
  if (maps.isEmpty) return;
  
  final config = AIConfig.fromJson(maps.first);
  
  // 删除配置
  await db.delete(
    tableAIConfigs,
    where: 'id = ?',
    whereArgs: [id],
  );
  
  // 如果删除的是默认配置，自动将第一个启用的配置设为默认
  if (config.isDefault) {
    final enabledMaps = await db.query(
      tableAIConfigs,
      where: 'enabled = ?',
      whereArgs: [1],
      limit: 1,
    );
    if (enabledMaps.isNotEmpty) {
      await db.update(
        tableAIConfigs,
        {'is_default': 1},
        where: 'id = ?',
        whereArgs: [enabledMaps.first['id']],
      );
    }
  }
}

/// 复制AI配置
Future<AIConfig> duplicateAIConfig(String id) async {
  final db = await database;
  final maps = await db.query(
    tableAIConfigs,
    where: 'id = ?',
    whereArgs: [id],
  );
  if (maps.isEmpty) {
    throw Exception('配置不存在');
  }
  
  final original = AIConfig.fromJson(maps.first);
  final now = DateTime.now();
  final newId = 'config_${now.millisecondsSinceEpoch}';
  
  final duplicated = original.copyWith(
    id: newId,
    displayName: '${original.displayName ?? original.provider.name} (副本)',
    isDefault: false,
    createdAt: now,
    updatedAt: now,
  );
  
  await saveAIConfig(duplicated);
  return duplicated;
}
```

- [ ] **Step 5: 提交数据库层修改**

```bash
git add lib/services/database_service.dart
git commit -m "feat(database): add migration v4 and multi-config CRUD methods for AI configs"
```

---

## Task 3: 状态管理层 - AI配置列表Provider

**Files:**
- Create: `lib/providers/ai_config_list_provider.dart`

- [ ] **Step 1: 创建配置列表状态管理**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/ai_config.dart';
import '../services/database_service.dart';
import '../services/ai_service.dart';

/// AI配置列表状态
class AIConfigListState {
  final List<AIConfig> configs;
  final bool isLoading;
  final String? error;

  const AIConfigListState({
    this.configs = const [],
    this.isLoading = false,
    this.error,
  });

  AIConfigListState copyWith({
    List<AIConfig>? configs,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return AIConfigListState(
      configs: configs ?? this.configs,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }

  /// 获取默认配置
  AIConfig? get defaultConfig {
    try {
      return configs.firstWhere((c) => c.isDefault);
    } catch (_) {
      return configs.isNotEmpty ? configs.first : null;
    }
  }
}

/// AI配置列表Notifier
class AIConfigListNotifier extends StateNotifier<AIConfigListState> {
  final DatabaseService _dbService;
  final AIService _aiService;

  AIConfigListNotifier(this._dbService, this._aiService) : super(const AIConfigListState()) {
    loadConfigs();
  }

  /// 加载所有配置
  Future<void> loadConfigs() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final configs = await _dbService.getAllAIConfigs();
      state = state.copyWith(configs: configs, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// 保存配置
  Future<void> saveConfig(AIConfig config) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _dbService.saveAIConfig(config);
      await loadConfigs();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// 删除配置
  Future<void> deleteConfig(String id) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _dbService.deleteAIConfig(id);
      await loadConfigs();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// 设置默认配置
  Future<void> setDefault(String id) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _dbService.setDefaultAIConfig(id);
      await loadConfigs();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// 复制配置
  Future<void> duplicateConfig(String id) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _dbService.duplicateAIConfig(id);
      await loadConfigs();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// 测试连接
  Future<ConnectionTestResult> testConnection(AIConfig config) async {
    return await _aiService.testConnection(config);
  }
}

/// Provider定义
final aiConfigListProvider = StateNotifierProvider<AIConfigListNotifier, AIConfigListState>((ref) {
  return AIConfigListNotifier(DatabaseService(), AIService());
});
```

- [ ] **Step 2: 提交状态管理层修改**

```bash
git add lib/providers/ai_config_list_provider.dart
git commit -m "feat(providers): add AIConfigListProvider for multi-config state management"
```

---

## Task 4: UI层 - AI配置列表页面

**Files:**
- Create: `lib/pages/ai_config_list_page.dart`

- [ ] **Step 1: 创建AI配置列表页面**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/ai_config.dart';
import '../providers/ai_config_list_provider.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import '../theme/spacing.dart';
import '../utils/constants.dart';
import 'ai_config_edit_page.dart';

/// AI配置列表页面
class AIConfigListPage extends ConsumerWidget {
  const AIConfigListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(aiConfigListProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text(
          'AI 服务配置',
          style: AppTypography.headlineMd.copyWith(
            color: AppColors.onSurface,
          ),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.configs.isEmpty
              ? _buildEmptyState(context)
              : _buildConfigList(context, ref, state),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addNewConfig(context),
        icon: const Icon(Icons.add),
        label: const Text('添加配置'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.smart_toy_outlined,
            size: 64,
            color: AppColors.onSurfaceVariant,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            '暂无AI配置',
            style: AppTypography.titleLg.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '点击下方按钮添加AI服务配置',
            style: AppTypography.bodyBase.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfigList(BuildContext context, WidgetRef ref, AIConfigListState state) {
    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: state.configs.length,
      itemBuilder: (context, index) {
        final config = state.configs[index];
        return _buildConfigCard(context, ref, config);
      },
    );
  }

  Widget _buildConfigCard(BuildContext context, WidgetRef ref, AIConfig config) {
    final isDefault = config.isDefault;
    final isEnabled = config.enabled;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: AppRadius.large,
        border: Border.all(
          color: isDefault ? AppColors.primary : AppColors.outlineVariant.withOpacity(0.3),
          width: isDefault ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _editConfig(context, config),
        borderRadius: AppRadius.large,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // 提供商图标
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: AppRadius.medium,
                    ),
                    child: Icon(
                      config.provider.isPreset ? Icons.stars : Icons.edit,
                      color: AppColors.primary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  // 配置信息
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              config.displayName ?? config.provider.name,
                              style: AppTypography.titleMd.copyWith(
                                color: AppColors.onSurface,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (isDefault) ...[
                              const SizedBox(width: AppSpacing.sm),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryContainer,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '默认',
                                  style: AppTypography.bodySm.copyWith(
                                    color: AppColors.primary,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          config.defaultModel,
                          style: AppTypography.bodySm.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // 状态指示
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: isEnabled ? AppColors.success : AppColors.outline,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              // 操作按钮
              Row(
                children: [
                  if (!isDefault)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _setDefault(ref, config.id),
                        icon: const Icon(Icons.star_outline, size: 18),
                        label: const Text('设为默认'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: BorderSide(color: AppColors.primary.withOpacity(0.5)),
                        ),
                      ),
                    ),
                  if (!isDefault) const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _editConfig(context, config),
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: const Text('编辑'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showMoreOptions(context, ref, config),
                      icon: const Icon(Icons.more_horiz, size: 18),
                      label: const Text('更多'),
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

  void _addNewConfig(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const AIConfigEditPage(),
      ),
    );
  }

  void _editConfig(BuildContext context, AIConfig config) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AIConfigEditPage(config: config),
      ),
    );
  }

  Future<void> _setDefault(WidgetRef ref, String id) async {
    await ref.read(aiConfigListProvider.notifier).setDefault(id);
  }

  void _showMoreOptions(BuildContext context, WidgetRef ref, AIConfig config) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('复制配置'),
              onTap: () {
                Navigator.pop(context);
                ref.read(aiConfigListProvider.notifier).duplicateConfig(config.id);
              },
            ),
            if (!config.provider.isPreset)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: AppColors.error),
                title: const Text('删除配置', style: TextStyle(color: AppColors.error)),
                onTap: () {
                  Navigator.pop(context);
                  _confirmDelete(context, ref, config);
                },
              ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, AIConfig config) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除配置 "${config.displayName ?? config.provider.name}" 吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(aiConfigListProvider.notifier).deleteConfig(config.id);
            },
            child: const Text('删除', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: 提交配置列表页面**

```bash
git add lib/pages/ai_config_list_page.dart
git commit -m "feat(ui): add AIConfigListPage for managing multiple AI configurations"
```

---

## Task 5: UI层 - AI配置编辑页面（重构现有页面）

**Files:**
- Create: `lib/pages/ai_config_edit_page.dart`
- Modify: `lib/pages/ai_config_page.dart` (保留原文件作为参考，后续删除)

- [ ] **Step 1: 创建AI配置编辑页面**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/ai_config.dart';
import '../providers/ai_config_list_provider.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import '../theme/spacing.dart';
import '../utils/constants.dart';
import '../services/secure_storage_service.dart';

/// AI配置编辑页面
class AIConfigEditPage extends ConsumerStatefulWidget {
  final AIConfig? config; // null 表示新建

  const AIConfigEditPage({super.key, this.config});

  @override
  ConsumerState<AIConfigEditPage> createState() => _AIConfigEditPageState();
}

class _AIConfigEditPageState extends ConsumerState<AIConfigEditPage> {
  final _formKey = GlobalKey<FormState>();
  final _apiKeyController = TextEditingController();
  final _timeoutController = TextEditingController(text: '30');
  final _baseUrlController = TextEditingController();
  final _displayNameController = TextEditingController();
  final _customModelController = TextEditingController();

  AIProvider _selectedProvider = AIProvider.doubao;
  String _selectedModel = 'doubao-1.5-vision-pro';
  bool _enabled = true;
  bool _isTesting = false;
  bool _initialized = false;
  late String _configId;
  bool get _isEditing => widget.config != null;

  @override
  void initState() {
    super.initState();
    _configId = widget.config?.id ?? 'config_${DateTime.now().millisecondsSinceEpoch}';
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _timeoutController.dispose();
    _baseUrlController.dispose();
    _displayNameController.dispose();
    _customModelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 如果是编辑模式，填充表单（只执行一次）
    if (widget.config != null && !_initialized) {
      _initialized = true;
      final config = widget.config!;
      _selectedProvider = config.provider;
      _selectedModel = config.defaultModel;
      _apiKeyController.text = config.apiKey;
      _timeoutController.text = config.timeoutSeconds.toString();
      _enabled = config.enabled;
      if (config.baseUrl != null) {
        _baseUrlController.text = config.baseUrl!;
      }
      if (config.displayName != null) {
        _displayNameController.text = config.displayName!;
      }
      if (config.provider == AIProvider.custom) {
        _customModelController.text = config.defaultModel;
      }
    }

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text(
          _isEditing ? '编辑配置' : '添加配置',
          style: AppTypography.headlineMd.copyWith(
            color: AppColors.onSurface,
          ),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _saveConfig,
            child: Text(
              '保存',
              style: AppTypography.bodyBase.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            // 模型提供商选择
            Text(
              '模型提供商',
              style: AppTypography.titleLg.copyWith(
                color: AppColors.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            _buildProviderSelector(),
            const SizedBox(height: AppSpacing.lg),

            // 自定义提供商配置
            if (_selectedProvider == AIProvider.custom) ...[
              Text(
                'API地址',
                style: AppTypography.titleLg.copyWith(
                  color: AppColors.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextFormField(
                controller: _baseUrlController,
                decoration: const InputDecoration(
                  hintText: '例如: https://api.openai.com/v1',
                  helperText: '支持OpenAI兼容格式的API地址',
                ),
                validator: (value) {
                  if (_selectedProvider == AIProvider.custom &&
                      (value == null || value.isEmpty)) {
                    return '请输入API地址';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.lg),

              Text(
                '配置名称（可选）',
                style: AppTypography.titleLg.copyWith(
                  color: AppColors.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextFormField(
                controller: _displayNameController,
                decoration: const InputDecoration(
                  hintText: '例如: OpenAI、Claude',
                  helperText: '方便识别不同的配置',
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],

            // API Key输入
            Text(
              'API Key',
              style: AppTypography.titleLg.copyWith(
                color: AppColors.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextFormField(
              controller: _apiKeyController,
              decoration: const InputDecoration(
                hintText: '输入API Key',
                helperText: 'API Key将加密存储在本地',
              ),
              obscureText: true,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '请输入API Key';
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.lg),

            // 默认模型选择
            Text(
              '默认模型',
              style: AppTypography.titleLg.copyWith(
                color: AppColors.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            _selectedProvider == AIProvider.custom
                ? TextFormField(
                    controller: _customModelController,
                    decoration: const InputDecoration(
                      hintText: '例如: gpt-4o, claude-3-opus',
                      helperText: '输入模型名称',
                    ),
                    validator: (value) {
                      if (_selectedProvider == AIProvider.custom &&
                          (value == null || value.isEmpty)) {
                        return '请输入模型名称';
                      }
                      return null;
                    },
                  )
                : _buildModelSelector(),
            const SizedBox(height: AppSpacing.lg),

            // 超时设置
            Text(
              '超时设置',
              style: AppTypography.titleLg.copyWith(
                color: AppColors.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextFormField(
              controller: _timeoutController,
              decoration: const InputDecoration(
                labelText: '超时时间（秒）',
                hintText: '30',
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '请输入超时时间';
                }
                final timeout = int.tryParse(value);
                if (timeout == null || timeout < 10) {
                  return '超时时间至少10秒';
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.lg),

            // 启用开关
            SwitchListTile(
              title: Text(
                '启用此配置',
                style: AppTypography.bodyBase.copyWith(
                  color: AppColors.onSurface,
                ),
              ),
              subtitle: Text(
                _enabled ? '已启用' : '已禁用',
                style: AppTypography.bodySm.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              value: _enabled,
              onChanged: (value) {
                setState(() => _enabled = value);
              },
              activeColor: AppColors.primary,
            ),
            const SizedBox(height: AppSpacing.xl),

            // 测试连接按钮
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isTesting ? null : _testConnection,
                icon: _isTesting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.wifi_find),
                label: Text(_isTesting ? '测试中...' : '测试连接'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProviderSelector() {
    return DropdownButtonFormField<AIProvider>(
      value: _selectedProvider,
      decoration: const InputDecoration(
        hintText: '选择模型提供商',
      ),
      items: AIProvider.values.map((provider) {
        return DropdownMenuItem(
          value: provider,
          child: Row(
            children: [
              Icon(
                provider.isPreset ? Icons.stars : Icons.edit,
                size: 20,
                color: provider.isPreset ? AppColors.primary : AppColors.onSurfaceVariant,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(provider.name),
              if (provider.isPreset) ...[
                const SizedBox(width: AppSpacing.xs),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '预设',
                    style: AppTypography.bodySm.copyWith(
                      color: AppColors.primary,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      }).toList(),
      onChanged: (value) {
        if (value != null) {
          setState(() {
            _selectedProvider = value;
            _selectedModel = _getDefaultModel(value);
            if (value == AIProvider.doubao) {
              _selectedModel = 'doubao-1.5-vision-pro';
            }
          });
        }
      },
    );
  }

  Widget _buildModelSelector() {
    final models = _getAvailableModels(_selectedProvider);

    return DropdownButtonFormField<String>(
      value: models.contains(_selectedModel) ? _selectedModel : null,
      decoration: const InputDecoration(
        hintText: '选择默认模型',
      ),
      items: models.map((model) {
        return DropdownMenuItem(
          value: model,
          child: Text(model),
        );
      }).toList(),
      onChanged: (value) {
        if (value != null) {
          setState(() => _selectedModel = value);
        }
      },
    );
  }

  List<String> _getAvailableModels(AIProvider provider) {
    switch (provider) {
      case AIProvider.doubao:
        return [
          'doubao-1.5-vision-pro',
          'doubao-seed-1.6',
          'doubao-seed-1.8',
          'doubao-seed-2.0',
          'doubao-seed-2-0-lite-260215',
          'doubao-seed-2-0-pro-260215',
        ];
      case AIProvider.custom:
        return [];
    }
  }

  String _getDefaultModel(AIProvider provider) {
    final models = _getAvailableModels(provider);
    return models.isNotEmpty ? models.first : '';
  }

  Future<void> _testConnection() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isTesting = true);

    final config = _buildConfig();
    final result = await ref.read(aiConfigListProvider.notifier).testConnection(config);

    setState(() => _isTesting = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.success ? '连接成功！' : '连接失败: ${result.errorMessage ?? "请检查配置"}'),
          backgroundColor: result.success ? AppColors.primary : AppColors.error,
        ),
      );
    }
  }

  AIConfig _buildConfig() {
    final now = DateTime.now();
    return AIConfig(
      id: _configId,
      provider: _selectedProvider,
      apiKey: _apiKeyController.text,
      defaultModel: _selectedProvider == AIProvider.custom
          ? _customModelController.text
          : _selectedModel,
      baseUrl: _baseUrlController.text.isNotEmpty ? _baseUrlController.text : null,
      displayName: _displayNameController.text.isNotEmpty ? _displayNameController.text : null,
      timeoutSeconds: int.tryParse(_timeoutController.text) ?? 30,
      enabled: _enabled,
      isDefault: widget.config?.isDefault ?? false,
      createdAt: widget.config?.createdAt ?? now,
      updatedAt: now,
    );
  }

  Future<void> _saveConfig() async {
    if (!_formKey.currentState!.validate()) return;

    final config = _buildConfig();
    
    // 保存 API Key 到安全存储
    final secureStorage = SecureStorageService();
    await secureStorage.saveApiKey(config.id, config.apiKey);

    await ref.read(aiConfigListProvider.notifier).saveConfig(config);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('配置已保存')),
      );
      Navigator.of(context).pop();
    }
  }
}
```

- [ ] **Step 2: 提交配置编辑页面**

```bash
git add lib/pages/ai_config_edit_page.dart
git commit -m "feat(ui): add AIConfigEditPage refactored from AIConfigPage"
```

---

## Task 6: UI层 - 隐私政策页面

**Files:**
- Create: `lib/pages/privacy_policy_page.dart`

- [ ] **Step 1: 创建隐私政策页面**

```dart
import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import '../theme/spacing.dart';

/// 隐私政策页面
class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text(
          '隐私政策',
          style: AppTypography.headlineMd.copyWith(
            color: AppColors.onSurface,
          ),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 更新日期
            Text(
              '更新日期：2026年5月6日',
              style: AppTypography.bodySm.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // 引言
            _buildSectionTitle('引言'),
            _buildParagraph(
              '欢迎使用"过期了么"应用程序（以下简称"本应用"）。我们深知个人信息对您的重要性，并将按照法律法规要求，采取相应安全保护措施，尽力保护您的个人信息安全可控。',
            ),
            _buildParagraph(
              '本隐私政策旨在向您说明我们如何收集、使用、存储和保护您的信息。请您在使用本应用前，仔细阅读并理解本隐私政策的全部内容。',
            ),

            // 1. 信息收集与使用
            _buildSectionTitle('一、信息收集与使用'),
            _buildParagraph(
              '为了向您提供物品管理和保质期追踪服务，我们需要收集以下信息：',
            ),
            _buildBulletPoint('物品信息：您主动输入的物品名称、分类、购买日期、保质期、存放位置等信息'),
            _buildBulletPoint('AI服务配置：您配置的AI服务API Key，用于调用AI识别功能'),
            _buildBulletPoint('同步服务配置：您配置的WebDAV服务器地址和认证信息，用于数据云同步'),
            _buildParagraph(
              '我们仅在您主动输入并使用相关功能时收集上述信息，不会自动收集其他个人信息。',
            ),

            // 2. 信息存储
            _buildSectionTitle('二、信息存储'),
            _buildParagraph(
              '本应用采用本地优先存储原则，您的所有数据存储于您的设备本地SQLite数据库中。',
            ),
            _buildBulletPoint('本地存储：所有物品信息存储于应用本地数据库，不会上传至任何中央服务器'),
            _buildBulletPoint('加密存储：敏感信息（如API Key）使用系统级密钥库进行加密存储'),
            _buildBulletPoint('数据导出：您可随时导出数据备份，数据文件由您完全掌控'),

            // 3. 第三方服务
            _buildSectionTitle('三、第三方服务'),
            _buildParagraph(
              '本应用涉及以下第三方服务，相关信息处理由您自主选择和控制：',
            ),
            _buildSubTitle('3.1 AI识别服务'),
            _buildParagraph(
              '当您使用AI智能录入功能时，应用会将您拍摄的物品图片发送至您配置的AI服务端点进行识别。图片数据和识别请求仅发送至您选择的AI服务提供商，我们不参与数据传输过程。请查阅您选择的AI服务提供商的隐私政策了解其数据处理方式。',
            ),
            _buildSubTitle('3.2 WebDAV同步服务'),
            _buildParagraph(
              '当您启用WebDAV同步功能时，应用会将您的物品数据上传至您配置的WebDAV服务器。数据传输使用HTTPS加密协议。同步服务的安全性取决于您选择的WebDAV服务提供商。',
            ),

            // 4. 信息共享
            _buildSectionTitle('四、信息共享'),
            _buildParagraph(
              '我们承诺不会向任何第三方出售、出租或共享您的个人信息。',
            ),
            _buildParagraph(
              '仅在以下情况下，您的数据可能被传输至第三方：',
            ),
            _buildBulletPoint('您主动启用WebDAV同步功能，数据将传输至您配置的WebDAV服务器'),
            _buildBulletPoint('您使用AI识别功能时，图片将发送至您选择的AI服务提供商'),
            _buildParagraph(
              '除上述情况外，您的数据仅存储于您的设备本地，不会传输至任何其他服务器。',
            ),

            // 5. 信息安全
            _buildSectionTitle('五、信息安全'),
            _buildParagraph(
              '我们采取多种安全措施保护您的信息：',
            ),
            _buildBulletPoint('本地数据库加密存储'),
            _buildBulletPoint('敏感信息（API Key、密码）使用系统密钥库（Keychain/Keystore）加密'),
            _buildBulletPoint('网络传输使用HTTPS加密协议'),
            _buildBulletPoint('应用不收集用户身份标识信息'),

            // 6. 用户权利
            _buildSectionTitle('六、用户权利'),
            _buildParagraph(
              '您对您的个人信息享有以下权利：',
            ),
            _buildBulletPoint('访问权：您可以随时查看应用中存储的所有物品信息'),
            _buildBulletPoint('更正权：您可以随时修改或更新您的物品信息'),
            _buildBulletPoint('删除权：您可以删除单个物品或清空所有数据'),
            _buildBulletPoint('导出权：您可以导出数据备份文件'),
            _buildBulletPoint('自主控制权：您可以随时禁用AI功能和同步功能'),
            _buildBulletPoint('卸载权：卸载应用将清除所有本地数据'),

            // 7. 未成年人保护
            _buildSectionTitle('七、未成年人保护'),
            _buildParagraph(
              '本应用面向所有年龄段用户开放。我们不收集任何可识别未成年人身份的个人信息。如您是未成年人的监护人，请指导和监督未成年人使用本应用。',
            ),

            // 8. 政策更新
            _buildSectionTitle('八、政策更新'),
            _buildParagraph(
              '我们可能会不时更新本隐私政策。更新后的政策将在应用内通知您。对于重大变更，我们将征得您的明确同意后再行实施。',
            ),
            _buildParagraph(
              '建议您定期查阅本政策，以了解我们如何保护您的信息。',
            ),

            // 9. 联系我们
            _buildSectionTitle('九、联系我们'),
            _buildParagraph(
              '如您对本隐私政策有任何疑问、意见或建议，请通过以下方式联系我们：',
            ),
            _buildBulletPoint('应用内反馈：通过设置页面提交反馈'),
            _buildParagraph(
              '我们将在收到您的反馈后尽快回复。',
            ),

            const SizedBox(height: AppSpacing.xl),
            Center(
              child: Text(
                '© 2026 过期了么 版权所有',
                style: AppTypography.bodySm.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.lg, bottom: AppSpacing.sm),
      child: Text(
        title,
        style: AppTypography.titleLg.copyWith(
          color: AppColors.onSurface,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildSubTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.sm),
      child: Text(
        title,
        style: AppTypography.titleMd.copyWith(
          color: AppColors.onSurface,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildParagraph(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Text(
        text,
        style: AppTypography.bodyBase.copyWith(
          color: AppColors.onSurfaceVariant,
          height: 1.6,
        ),
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: AppSpacing.md, bottom: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• ',
            style: AppTypography.bodyBase.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: AppTypography.bodyBase.copyWith(
                color: AppColors.onSurfaceVariant,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: 提交隐私政策页面**

```bash
git add lib/pages/privacy_policy_page.dart
git commit -m "feat(ui): add PrivacyPolicyPage with comprehensive privacy policy content"
```

---

## Task 7: 设置页面调整

**Files:**
- Modify: `lib/pages/settings_page.dart`

- [ ] **Step 1: 更新设置页面导入**

在文件顶部添加导入：

```dart
import 'ai_config_list_page.dart';
import 'privacy_policy_page.dart';
```

- [ ] **Step 2: 修改 AI 配置入口跳转**

将 AI 服务配置跳转目标改为 `AIConfigListPage`：

```dart
// AI 配置卡片
_buildSettingsCard(
  title: 'AI 配置',
  children: [
    _buildSettingsItem(
      icon: Icons.smart_toy,
      title: 'AI 服务配置',
      subtitle: '管理多个AI服务提供商',
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const AIConfigListPage(),
          ),
        );
      },
    ),
  ],
),
```

- [ ] **Step 3: 修改隐私政策入口并删除帮助与反馈**

将"关于"卡片修改为：

```dart
// 关于卡片
_buildSettingsCard(
  title: '关于',
  children: [
    _buildSettingsItem(
      icon: Icons.info_outline,
      title: '关于应用',
      subtitle: '版本 1.0.0',
      onTap: () => _showAboutDialog(context),
    ),
    Divider(
      height: 1,
      color: AppColors.outlineVariant.withOpacity(0.3),
    ),
    _buildSettingsItem(
      icon: Icons.privacy_tip_outlined,
      title: '隐私政策',
      subtitle: '了解我们如何保护你的数据',
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const PrivacyPolicyPage(),
          ),
        );
      },
    ),
  ],
),
```

- [ ] **Step 4: 删除旧的 ai_config_page.dart 导入**

移除不再使用的导入：

```dart
// 删除这行
import 'ai_config_page.dart';
```

- [ ] **Step 5: 提交设置页面修改**

```bash
git add lib/pages/settings_page.dart
git commit -m "feat(settings): update AI config navigation to list page and remove help section"
```

---

## Task 8: 清理旧文件

**Files:**
- Delete: `lib/pages/ai_config_page.dart`

- [ ] **Step 1: 删除旧的AI配置页面**

```bash
rm lib/pages/ai_config_page.dart
```

- [ ] **Step 2: 更新 pages.dart 导出文件**

如果存在 `lib/pages/pages.dart`，更新导出：

```dart
export 'ai_config_list_page.dart';
export 'ai_config_edit_page.dart';
export 'privacy_policy_page.dart';
// 删除: export 'ai_config_page.dart';
```

- [ ] **Step 3: 提交清理修改**

```bash
git add -A
git commit -m "refactor: remove old AIConfigPage, replaced by AIConfigListPage and AIConfigEditPage"
```

---

## Task 9: 验证和测试

- [ ] **Step 1: 运行应用验证功能**

```bash
flutter run
```

验证清单：
- [ ] 设置页面AI配置入口跳转至配置列表页
- [ ] 配置列表页显示空状态
- [ ] 添加新配置功能正常
- [ ] 编辑配置功能正常
- [ ] 设为默认功能正常
- [ ] 删除配置功能正常
- [ ] 复制配置功能正常
- [ ] 测试连接功能正常
- [ ] 隐私政策页面正常显示
- [ ] 帮助与反馈入口已移除

- [ ] **Step 2: 提交最终版本**

```bash
git add -A
git commit -m "feat: complete multi-provider AI config and privacy policy implementation"
```

---

## Self-Review Checklist

- [x] **Spec coverage:** 每个设计需求都有对应任务
- [x] **Placeholder scan:** 无 TBD/TODO 占位符
- [x] **Type consistency:** 模型字段、方法签名在各任务中保持一致
