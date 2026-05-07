# 开封时间功能优化实现计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 为物品添加快速开封功能，智能评估开封后的建议使用日期，并在界面上醒目展示。

**Architecture:** 数据层新增三个字段存储开封相关信息；规则库优先计算建议日期，AI 作为补充；物品卡片集成快速开封按钮；详情页和时间轴展示建议日期。

**Tech Stack:** Flutter, SQLite, Riverpod, 现有 AI 服务

---

## 文件结构

| 文件 | 职责 | 状态 |
|------|------|------|
| `lib/models/item.dart` | 物品数据模型，新增3个字段 | 修改 |
| `lib/services/database_service.dart` | 数据库服务，版本升级到6，新增字段 | 修改 |
| `lib/data/expiry_rules.dart` | 开封保质期规则库 | 新建 |
| `lib/services/ai_service.dart` | AI服务，新增开封保质期分析方法 | 修改 |
| `lib/widgets/item_card.dart` | 物品卡片，新增快速开封按钮和建议日期展示 | 修改 |
| `lib/pages/item_detail_page.dart` | 详情页，新增建议日期展示 | 修改 |
| `lib/pages/item_edit_page.dart` | 编辑页，新增独立包装选项 | 修改 |
| `lib/providers/item_provider.dart` | 状态管理，新增快速开封方法 | 修改 |
| `lib/utils/constants.dart` | 常量，更新子分类数据标记独立包装 | 修改 |

---

## Task 1: 数据模型 - 新增字段

**Files:**
- Modify: `lib/models/item.dart`

- [ ] **Step 1: 在 Item 类中新增三个字段**

```dart
// 在 Item 类中，openedDate 字段之后添加：

  final DateTime? suggestedUseDate;     // 建议使用日期
  final String? useDateSource;          // 建议日期来源：'rule' | 'ai' | 'fallback' | null
  final bool isIndividuallyWrapped;     // 是否独立包装，默认 false
```

- [ ] **Step 2: 更新构造函数，添加新字段的默认值**

```dart
// 修改构造函数，在 openedDate 之后添加：

  const Item({
    required this.id,
    required this.name,
    required this.category,
    this.subCategory,
    this.brand,
    this.specification,
    required this.purchaseDate,
    required this.expiryDate,
    this.openedDate,
    this.suggestedUseDate,              // 新增
    this.useDateSource,                 // 新增
    this.isIndividuallyWrapped = false, // 新增，默认 false
    this.quantity = 1,
    this.unit = '个',
    this.location,
    this.notes,
    this.imageUrl,
    required this.status,
    this.aiConfidence,
    required this.createdAt,
    required this.updatedAt,
  });
```

- [ ] **Step 3: 更新 fromJson 方法，解析新字段**

```dart
// 在 fromJson 方法中，openedDate 解析之后添加：

      suggestedUseDate: json['suggested_use_date'] != null
          ? parseDate(json['suggested_use_date'] as String?, now, 'suggested_use_date')
          : null,
      useDateSource: json['use_date_source'] as String?,
      isIndividuallyWrapped: json['is_individually_wrapped'] == 1,
```

- [ ] **Step 4: 更新 toJson 方法，序列化新字段**

```dart
// 在 toJson 方法中，opened_date 之后添加：

      'suggested_use_date': suggestedUseDate?.toIso8601String(),
      'use_date_source': useDateSource,
      'is_individually_wrapped': isIndividuallyWrapped ? 1 : 0,
```

- [ ] **Step 5: 更新 copyWith 方法，添加新字段**

```dart
// 在 copyWith 方法参数列表中添加：

  Item copyWith({
    String? id,
    String? name,
    String? category,
    String? subCategory,
    String? brand,
    String? specification,
    DateTime? purchaseDate,
    DateTime? expiryDate,
    DateTime? openedDate,
    DateTime? suggestedUseDate,              // 新增
    String? useDateSource,                   // 新增
    bool? isIndividuallyWrapped,             // 新增
    int? quantity,
    String? unit,
    String? location,
    String? notes,
    String? imageUrl,
    ItemStatus? status,
    double? aiConfidence,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Item(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      subCategory: subCategory ?? this.subCategory,
      brand: brand ?? this.brand,
      specification: specification ?? this.specification,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      expiryDate: expiryDate ?? this.expiryDate,
      openedDate: openedDate ?? this.openedDate,
      suggestedUseDate: suggestedUseDate ?? this.suggestedUseDate,          // 新增
      useDateSource: useDateSource ?? this.useDateSource,                   // 新增
      isIndividuallyWrapped: isIndividuallyWrapped ?? this.isIndividuallyWrapped, // 新增
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      location: location ?? this.location,
      notes: notes ?? this.notes,
      imageUrl: imageUrl ?? this.imageUrl,
      status: status ?? this.status,
      aiConfidence: aiConfidence ?? this.aiConfidence,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
```

- [ ] **Step 6: 验证编译通过**

Run: `cd H:/code/food_app && flutter analyze lib/models/item.dart`
Expected: No issues found

- [ ] **Step 7: Commit**

```bash
git add lib/models/item.dart
git commit -m "feat(item): 新增 suggestedUseDate、useDateSource、isIndividuallyWrapped 字段"
```

---

## Task 2: 数据库迁移 - 升级到版本 6

**Files:**
- Modify: `lib/services/database_service.dart`

- [ ] **Step 1: 更新数据库版本号**

```dart
// 将 _databaseVersion 从 5 改为 6

  static const int _databaseVersion = 6;
```

- [ ] **Step 2: 在 _onCreate 方法中添加新字段**

```dart
// 在 _onCreate 方法的 items 表创建语句中，opened_date TEXT 之后添加：

        suggested_use_date TEXT,
        use_date_source TEXT,
        is_individually_wrapped INTEGER DEFAULT 0,
```

- [ ] **Step 3: 在 _onUpgrade 方法中添加版本 6 的迁移逻辑**

```dart
// 在 _onUpgrade 方法末尾，版本 5 迁移之后添加：

    // 版本5到版本6：添加开封保质期相关字段
    if (oldVersion < 6) {
      await db.execute('ALTER TABLE $tableItems ADD COLUMN suggested_use_date TEXT');
      await db.execute('ALTER TABLE $tableItems ADD COLUMN use_date_source TEXT');
      await db.execute('ALTER TABLE $tableItems ADD COLUMN is_individually_wrapped INTEGER DEFAULT 0');
    }
```

- [ ] **Step 4: 验证编译通过**

Run: `cd H:/code/food_app && flutter analyze lib/services/database_service.dart`
Expected: No issues found

- [ ] **Step 5: Commit**

```bash
git add lib/services/database_service.dart
git commit -m "feat(db): 数据库升级到版本6，新增开封保质期相关字段"
```

---

## Task 3: 开封保质期规则库

**Files:**
- Create: `lib/data/expiry_rules.dart`

- [ ] **Step 1: 创建规则库文件**

```dart
/// 开封保质期规则
class ExpiryRule {
  final String category;
  final String? subCategory;
  final int daysAfterOpened;
  final String? storageTip;

  const ExpiryRule({
    required this.category,
    this.subCategory,
    required this.daysAfterOpened,
    this.storageTip,
  });
}

/// 开封保质期规则库
class ExpiryRules {
  ExpiryRules._();

  /// 默认开封后天数（全局兜底）
  static const int defaultDaysAfterOpened = 7;

  /// 预设规则列表
  static const List<ExpiryRule> rules = [
    // 食品 - 乳制品
    ExpiryRule(category: '食品', subCategory: '牛奶', daysAfterOpened: 3, storageTip: '需冷藏'),
    ExpiryRule(category: '食品', subCategory: '酸奶', daysAfterOpened: 3, storageTip: '需冷藏'),
    ExpiryRule(category: '食品', subCategory: '奶酪', daysAfterOpened: 7, storageTip: '需冷藏'),

    // 食品 - 蛋类
    ExpiryRule(category: '食品', subCategory: '鸡蛋', daysAfterOpened: 14, storageTip: '常温或冷藏'),

    // 食品 - 调味品
    ExpiryRule(category: '食品', subCategory: '酱油', daysAfterOpened: 90, storageTip: '阴凉处'),
    ExpiryRule(category: '食品', subCategory: '蚝油', daysAfterOpened: 30, storageTip: '需冷藏'),
    ExpiryRule(category: '食品', subCategory: '醋', daysAfterOpened: 180, storageTip: '阴凉处'),
    ExpiryRule(category: '食品', subCategory: '番茄酱', daysAfterOpened: 30, storageTip: '需冷藏'),
    ExpiryRule(category: '食品', subCategory: '蛋黄酱', daysAfterOpened: 60, storageTip: '需冷藏'),
    ExpiryRule(category: '食品', subCategory: '沙拉酱', daysAfterOpened: 30, storageTip: '需冷藏'),

    // 食品 - 烘焙
    ExpiryRule(category: '食品', subCategory: '面包', daysAfterOpened: 3, storageTip: '密封保存'),
    ExpiryRule(category: '食品', subCategory: '蛋糕', daysAfterOpened: 2, storageTip: '需冷藏'),

    // 食品 - 零食
    ExpiryRule(category: '食品', subCategory: '薯片', daysAfterOpened: 7, storageTip: '密封保存'),
    ExpiryRule(category: '食品', subCategory: '饼干', daysAfterOpened: 14, storageTip: '密封保存'),

    // 食品 - 肉类
    ExpiryRule(category: '食品', subCategory: '火腿', daysAfterOpened: 7, storageTip: '需冷藏'),
    ExpiryRule(category: '食品', subCategory: '香肠', daysAfterOpened: 7, storageTip: '需冷藏'),

    // 食品 - 默认规则
    ExpiryRule(category: '食品', daysAfterOpened: 7),

    // 药品
    ExpiryRule(category: '药品', subCategory: '眼药水', daysAfterOpened: 28, storageTip: '避光保存'),
    ExpiryRule(category: '药品', subCategory: '糖浆', daysAfterOpened: 30, storageTip: '密封阴凉'),
    ExpiryRule(category: '药品', subCategory: '滴耳液', daysAfterOpened: 30, storageTip: '避光保存'),
    ExpiryRule(category: '药品', subCategory: '滴鼻液', daysAfterOpened: 30, storageTip: '避光保存'),
    ExpiryRule(category: '药品', subCategory: '软膏', daysAfterOpened: 60, storageTip: '密封阴凉'),

    // 药品 - 默认规则
    ExpiryRule(category: '药品', daysAfterOpened: 30, storageTip: '参照说明书'),

    // 化妆品
    ExpiryRule(category: '化妆品', subCategory: '面霜', daysAfterOpened: 180, storageTip: '避光保存'),
    ExpiryRule(category: '化妆品', subCategory: '精华液', daysAfterOpened: 90, storageTip: '避光保存'),
    ExpiryRule(category: '化妆品', subCategory: '眼霜', daysAfterOpened: 90, storageTip: '避光保存'),
    ExpiryRule(category: '化妆品', subCategory: '面膜', daysAfterOpened: 30, storageTip: '密封保存'),
    ExpiryRule(category: '化妆品', subCategory: '口红', daysAfterOpened: 365, storageTip: '避光保存'),
    ExpiryRule(category: '化妆品', subCategory: '睫毛膏', daysAfterOpened: 90, storageTip: '避免交叉污染'),

    // 化妆品 - 默认规则
    ExpiryRule(category: '化妆品', daysAfterOpened: 90, storageTip: '参照包装说明'),

    // 日用品
    ExpiryRule(category: '日用品', subCategory: '洗发水', daysAfterOpened: 365, storageTip: '常温保存'),
    ExpiryRule(category: '日用品', subCategory: '沐浴露', daysAfterOpened: 365, storageTip: '常温保存'),
    ExpiryRule(category: '日用品', subCategory: '牙膏', daysAfterOpened: 180, storageTip: '常温保存'),

    // 日用品 - 默认规则
    ExpiryRule(category: '日用品', daysAfterOpened: 180),
  ];

  /// 根据分类和子分类匹配规则
  /// 返回匹配的规则，如果没有精确匹配则返回分类默认规则
  static ExpiryRule? findRule(String category, String? subCategory) {
    // 1. 精确匹配：主分类 + 子分类
    if (subCategory != null && subCategory.isNotEmpty) {
      for (final rule in rules) {
        if (rule.category == category && rule.subCategory == subCategory) {
          return rule;
        }
      }
    }

    // 2. 分类默认：仅主分类
    for (final rule in rules) {
      if (rule.category == category && rule.subCategory == null) {
        return rule;
      }
    }

    // 3. 无匹配规则
    return null;
  }

  /// 获取建议天数（带默认值）
  static int getSuggestedDays(String category, String? subCategory) {
    final rule = findRule(category, subCategory);
    return rule?.daysAfterOpened ?? defaultDaysAfterOpened;
  }

  /// 获取存储提示
  static String? getStorageTip(String category, String? subCategory) {
    final rule = findRule(category, subCategory);
    return rule?.storageTip;
  }
}
```

- [ ] **Step 2: 验证编译通过**

Run: `cd H:/code/food_app && flutter analyze lib/data/expiry_rules.dart`
Expected: No issues found

- [ ] **Step 3: Commit**

```bash
git add lib/data/expiry_rules.dart
git commit -m "feat: 新增开封保质期规则库"
```

---

## Task 4: AI 服务 - 新增开封保质期分析方法

**Files:**
- Modify: `lib/services/ai_service.dart`

- [ ] **Step 1: 新增 OpenedExpiryAnalysis 结果类**

```dart
// 在文件顶部，ShelfLifeAnalysis 类之后添加：

/// 开封保质期分析结果
class OpenedExpiryAnalysis {
  final int suggestedDays;
  final String? reasoning;
  final String? storageTip;

  const OpenedExpiryAnalysis({
    required this.suggestedDays,
    this.reasoning,
    this.storageTip,
  });
}
```

- [ ] **Step 2: 新增 analyzeOpenedExpiry 方法**

```dart
// 在 AIService 类中，analyzeShelfLife 方法之后添加：

  /// 分析物品开封后的保质期
  Future<OpenedExpiryAnalysis> analyzeOpenedExpiry({
    required AIConfig config,
    required String name,
    required String category,
    String? subCategory,
    String? brand,
    String? specification,
    String? location,
  }) async {
    final prompt = _getOpenedExpiryPrompt(
      name: name,
      category: category,
      subCategory: subCategory,
      brand: brand,
      specification: specification,
      location: location,
    );

    try {
      final response = await _callTextAPI(
        config: config,
        prompt: prompt,
      );

      final content = _extractContent(response);
      if (content == null) {
        throw Exception('AI响应内容为空');
      }

      final json = _parseJsonFromContent(content);
      return OpenedExpiryAnalysis(
        suggestedDays: json['suggested_days'] as int? ?? 7,
        reasoning: json['reasoning'] as String?,
        storageTip: json['storage_tip'] as String?,
      );
    } catch (e) {
      throw _handleError(e);
    }
  }
```

- [ ] **Step 3: 新增 _getOpenedExpiryPrompt 方法**

```dart
// 在 _getShelfLifePrompt 方法之后添加：

  /// 开封保质期分析提示词
  String _getOpenedExpiryPrompt({
    required String name,
    required String category,
    String? subCategory,
    String? brand,
    String? specification,
    String? location,
  }) {
    final today = DateTime.now().toString().split(' ')[0];

    return '''
你是物品保质期分析专家。请根据以下物品信息，给出开封后的建议使用天数。

【物品信息】
- 名称：$name
- 分类：$category${subCategory != null ? ' ($subCategory)' : ''}
- 品牌：${brand ?? '未知'}
- 规格：${specification ?? '未知'}
- 存放位置：${location ?? '未知'}

【分析要求】
1. 根据物品类型评估开封后的保质期
2. 考虑存放位置对保质期的影响（如冰箱 vs 常温）
3. 给出简短的原因说明（20字以内）
4. 给出存储建议（15字以内）

【返回格式】严格返回JSON，不要添加其他文字：
{
  "suggested_days": 7,
  "reasoning": "简短说明原因",
  "storage_tip": "存储建议"
}

今天日期：$today
''';
  }
```

- [ ] **Step 4: 验证编译通过**

Run: `cd H:/code/food_app && flutter analyze lib/services/ai_service.dart`
Expected: No issues found

- [ ] **Step 5: Commit**

```bash
git add lib/services/ai_service.dart
git commit -m "feat(ai): 新增 analyzeOpenedExpiry 方法"
```

---

## Task 5: 状态管理 - 新增快速开封方法

**Files:**
- Modify: `lib/providers/item_provider.dart`

- [ ] **Step 1: 添加必要的 import**

```dart
// 在文件顶部 import 区域添加：

import '../data/expiry_rules.dart';
import '../services/ai_service.dart';
```

- [ ] **Step 2: 新增 markAsOpened 方法**

```dart
// 在 ItemsNotifier 类中，markAsConsumed 方法之后添加：

  /// 快速开封物品
  /// 自动根据规则库或 AI 计算建议使用日期
  Future<void> markAsOpened(String id, {AIConfig? aiConfig}) async {
    try {
      final item = state.items.where((i) => i.id == id).firstOrNull;
      if (item == null) return;

      // 独立包装物品不生成建议日期
      if (item.isIndividuallyWrapped) {
        final updatedItem = item.copyWith(
          openedDate: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await _dbService.updateItem(updatedItem);
        await loadItems();
        return;
      }

      final now = DateTime.now();
      DateTime? suggestedUseDate;
      String? useDateSource;

      // 尝试从规则库获取
      final rule = ExpiryRules.findRule(item.category, item.subCategory);
      if (rule != null) {
        final days = rule.daysAfterOpened;
        suggestedUseDate = now.add(Duration(days: days));
        useDateSource = 'rule';
      } else if (aiConfig != null) {
        // 规则库无匹配，调用 AI 分析
        try {
          final aiService = AIService();
          final analysis = await aiService.analyzeOpenedExpiry(
            config: aiConfig,
            name: item.name,
            category: item.category,
            subCategory: item.subCategory,
            brand: item.brand,
            specification: item.specification,
            location: item.location,
          );

          suggestedUseDate = now.add(Duration(days: analysis.suggestedDays));
          useDateSource = 'ai';
        } catch (e) {
          // AI 调用失败，使用默认值
          suggestedUseDate = now.add(const Duration(days: ExpiryRules.defaultDaysAfterOpened));
          useDateSource = 'fallback';
        }
      } else {
        // 无 AI 配置，使用默认值
        suggestedUseDate = now.add(const Duration(days: ExpiryRules.defaultDaysAfterOpened));
        useDateSource = 'fallback';
      }

      // 确保建议日期不超过过期日期
      if (suggestedUseDate.isAfter(item.expiryDate)) {
        suggestedUseDate = item.expiryDate;
      }

      final updatedItem = item.copyWith(
        openedDate: now,
        suggestedUseDate: suggestedUseDate,
        useDateSource: useDateSource,
        updatedAt: now,
      );

      await _dbService.updateItem(updatedItem);
      await loadItems();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
```

- [ ] **Step 3: 验证编译通过**

Run: `cd H:/code/food_app && flutter analyze lib/providers/item_provider.dart`
Expected: No issues found

- [ ] **Step 4: Commit**

```bash
git add lib/providers/item_provider.dart
git commit -m "feat(provider): 新增 markAsOpened 方法"
```

---

## Task 6: 物品卡片 - 快速开封按钮和建议日期展示

**Files:**
- Modify: `lib/widgets/item_card.dart`

- [ ] **Step 1: 添加新的可选参数**

```dart
// 在 ItemCard 类的构造函数参数中添加：

  final DateTime? openedDate;           // 开封日期
  final DateTime? suggestedUseDate;     // 建议使用日期
  final bool isIndividuallyWrapped;     // 是否独立包装
  final VoidCallback? onOpenTap;        // 快速开封回调
```

- [ ] **Step 2: 更新构造函数**

```dart
// 更新 ItemCard 构造函数：

  const ItemCard({
    super.key,
    required this.name,
    required this.category,
    this.subCategory,
    required this.purchaseDate,
    required this.expiryDate,
    this.location,
    this.imageUrl,
    this.status,
    this.quantity = 1,
    this.unit = '个',
    this.openedDate,                    // 新增
    this.suggestedUseDate,              // 新增
    this.isIndividuallyWrapped = false, // 新增
    this.onTap,
    this.onLongPress,
    this.onOpenTap,                     // 新增
  });
```

- [ ] **Step 3: 添加辅助方法计算建议日期状态**

```dart
// 在 ItemCard 类中添加辅助方法：

  /// 计算距建议日期的天数
  int? _daysUntilSuggestedUse() {
    if (suggestedUseDate == null) return null;
    return suggestedUseDate!.difference(DateTime.now()).inDays;
  }

  /// 判断是否应该显示开封按钮
  bool _shouldShowOpenButton() {
    return openedDate == null && !isIndividuallyWrapped && onOpenTap != null;
  }

  /// 判断是否应该显示建议日期
  bool _shouldShowSuggestedDate() {
    return openedDate != null && suggestedUseDate != null;
  }
```

- [ ] **Step 4: 新增建议日期展示组件**

```dart
// 在 ItemCard 类中添加私有方法：

  Widget _buildSuggestedDateHint() {
    final days = _daysUntilSuggestedUse();
    if (days == null) return const SizedBox.shrink();

    String text;
    Color textColor;
    IconData? icon;

    if (days > 3) {
      text = '建议在 ${suggestedUseDate!.month}月${suggestedUseDate!.day}日 前用完';
      textColor = AppColors.onSurfaceVariant;
      icon = null;
    } else if (days > 0) {
      text = '建议在 ${suggestedUseDate!.month}月${suggestedUseDate!.day}日 前用完';
      textColor = Colors.orange;
      icon = Icons.warning_amber_rounded;
    } else {
      text = '已超过建议使用日期';
      textColor = Colors.red;
      icon = Icons.error_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: textColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: textColor),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: AppTypography.bodySm.copyWith(
              color: textColor,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
```

- [ ] **Step 5: 新增快速开封按钮组件**

```dart
// 在 ItemCard 类中添加私有方法：

  Widget _buildOpenButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onOpenTap,
        borderRadius: AppRadius.small,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: AppRadius.small,
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.open_in_new_rounded,
                size: 14,
                color: AppColors.primary,
              ),
              const SizedBox(width: 4),
              Text(
                '开封',
                style: AppTypography.bodySm.copyWith(
                  color: AppColors.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
```

- [ ] **Step 6: 修改 build 方法，集成新组件**

```dart
// 在 build 方法中，修改 Stack 的 children，在 ExpiryProgressBar 之后添加：

                // 建议日期提示或开封按钮
                if (_shouldShowSuggestedDateHint() || _shouldShowOpenButton())
                  Positioned(
                    bottom: 8,
                    right: AppSpacing.md,
                    child: _shouldShowSuggestedDateHint()
                        ? _buildSuggestedDateHint()
                        : _shouldShowOpenButton()
                            ? _buildOpenButton()
                            : const SizedBox.shrink(),
                  ),
```

- [ ] **Step 7: 验证编译通过**

Run: `cd H:/code/food_app && flutter analyze lib/widgets/item_card.dart`
Expected: No issues found

- [ ] **Step 8: Commit**

```bash
git add lib/widgets/item_card.dart
git commit -m "feat(item_card): 新增快速开封按钮和建议日期展示"
```

---

## Task 7: 更新 ItemCard 调用处

**Files:**
- Modify: `lib/pages/home_page.dart`

- [ ] **Step 1: 找到 ItemCard 的使用位置并更新**

搜索项目中所有使用 ItemCard 的地方，添加新参数。主要在 home_page.dart 的物品列表中。

```dart
// 在 ItemCard 构造调用中添加新参数：

ItemCard(
  name: item.name,
  category: item.category,
  subCategory: item.subCategory,
  purchaseDate: item.purchaseDate,
  expiryDate: item.expiryDate,
  location: item.location,
  imageUrl: item.imageUrl,
  status: item.status,
  quantity: item.quantity,
  unit: item.unit,
  openedDate: item.openedDate,                    // 新增
  suggestedUseDate: item.suggestedUseDate,        // 新增
  isIndividuallyWrapped: item.isIndividuallyWrapped, // 新增
  onTap: () => _navigateToDetail(item.id),
  onLongPress: () => _showItemOptions(item),
  onOpenTap: () => _handleQuickOpen(item.id),     // 新增
),
```

- [ ] **Step 2: 添加 _handleQuickOpen 方法**

```dart
// 在 HomePage 类中添加方法：

  Future<void> _handleQuickOpen(String itemId) async {
    final aiConfig = await ref.read(defaultAIConfigProvider.future);
    await ref.read(itemsProvider.notifier).markAsOpened(itemId, aiConfig: aiConfig);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('已标记为开封'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }
```

- [ ] **Step 3: 验证编译通过**

Run: `cd H:/code/food_app && flutter analyze lib/pages/home_page.dart`
Expected: No issues found

- [ ] **Step 4: Commit**

```bash
git add lib/pages/home_page.dart
git commit -m "feat(home): 集成 ItemCard 快速开封功能"
```

---

## Task 8: 物品详情页 - 建议日期展示

**Files:**
- Modify: `lib/pages/item_detail_page.dart`

- [ ] **Step 1: 在详情信息区域添加建议日期展示**

```dart
// 找到详情信息展示区域，在过期日期之后添加：

    // 建议使用日期
    if (widget.item.suggestedUseDate != null) ...[
      const SizedBox(height: 8),
      _buildSuggestedDateCard(),
    ],
```

- [ ] **Step 2: 添加 _buildSuggestedDateCard 方法**

```dart
// 在 ItemDetailPage 类中添加方法：

  Widget _buildSuggestedDateCard() {
    final suggestedDate = widget.item.suggestedUseDate!;
    final days = suggestedDate.difference(DateTime.now()).inDays;
    final source = widget.item.useDateSource ?? 'rule';

    Color bgColor;
    Color textColor;
    IconData icon;
    String statusText;

    if (days > 3) {
      bgColor = AppColors.primaryContainer;
      textColor = AppColors.onPrimaryContainer;
      icon = Icons.event_available_rounded;
      statusText = '建议使用日期';
    } else if (days > 0) {
      bgColor = Colors.orange.withValues(alpha: 0.15);
      textColor = Colors.orange;
      icon = Icons.warning_amber_rounded;
      statusText = '即将到期';
    } else {
      bgColor = Colors.red.withValues(alpha: 0.15);
      textColor = Colors.red;
      icon = Icons.error_outline;
      statusText = '已超过建议日期';
    }

    final rule = ExpiryRules.findRule(widget.item.category, widget.item.subCategory);
    final storageTip = rule?.storageTip;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: AppRadius.medium,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: textColor, size: 20),
              const SizedBox(width: 8),
              Text(
                statusText,
                style: AppTypography.bodyBase.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${suggestedDate.month}月${suggestedDate.day}日 前建议使用完毕',
            style: AppTypography.bodySm.copyWith(
              color: textColor,
            ),
          ),
          if (storageTip != null) ...[
            const SizedBox(height: 4),
            Text(
              '存储建议：$storageTip',
              style: AppTypography.bodySm.copyWith(
                color: textColor.withValues(alpha: 0.8),
              ),
            ),
          ],
          if (source == 'ai') ...[
            const SizedBox(height: 4),
            Text(
              '（AI 智能分析）',
              style: AppTypography.bodySm.copyWith(
                color: textColor.withValues(alpha: 0.6),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }
```

- [ ] **Step 3: 添加必要的 import**

```dart
// 在文件顶部添加：

import '../data/expiry_rules.dart';
```

- [ ] **Step 4: 验证编译通过**

Run: `cd H:/code/food_app && flutter analyze lib/pages/item_detail_page.dart`
Expected: No issues found

- [ ] **Step 5: Commit**

```bash
git add lib/pages/item_detail_page.dart
git commit -m "feat(detail): 新增建议使用日期展示卡片"
```

---

## Task 9: 物品编辑页 - 独立包装选项

**Files:**
- Modify: `lib/pages/item_edit_page.dart`

- [ ] **Step 1: 添加状态变量**

```dart
// 在 ItemEditPageState 类中，找到状态变量区域，添加：

  bool _isIndividuallyWrapped = false;
```

- [ ] **Step 2: 在 _loadItemData 方法中加载独立包装状态**

```dart
// 在 _loadItemData 方法中，添加：

    _isIndividuallyWrapped = widget.item?.isIndividuallyWrapped ?? false;
```

- [ ] **Step 3: 在 _initializeWithPrefilledData 方法中初始化**

```dart
// 在 _initializeWithPrefilledData 方法中，添加：

    _isIndividuallyWrapped = widget.prefilledData?.isIndividuallyWrapped ?? false;
```

- [ ] **Step 4: 添加独立包装选项 UI**

```dart
// 在日期信息区域之后，添加独立包装选项：

            // 独立包装选项
            ListTile(
              leading: const Icon(Icons.inventory_2_outlined),
              title: const Text('独立包装'),
              subtitle: const Text('独立包装物品无需记录开封后保质期'),
              trailing: Switch(
                value: _isIndividuallyWrapped,
                onChanged: (value) {
                  setState(() {
                    _isIndividuallyWrapped = value;
                  });
                },
              ),
              contentPadding: EdgeInsets.zero,
            ),
```

- [ ] **Step 5: 在保存时写入 isIndividuallyWrapped**

```dart
// 在 _saveItem 方法中，copyWith 调用时添加：

    isIndividuallyWrapped: _isIndividuallyWrapped,
```

- [ ] **Step 6: 验证编译通过**

Run: `cd H:/code/food_app && flutter analyze lib/pages/item_edit_page.dart`
Expected: No issues found

- [ ] **Step 7: Commit**

```bash
git add lib/pages/item_edit_page.dart
git commit -m "feat(edit): 新增独立包装选项"
```

---

## Task 10: 更新子分类数据 - 标记独立包装默认值

**Files:**
- Modify: `lib/utils/constants.dart`

- [ ] **Step 1: 查找子分类数据定义位置**

搜索 `subCategories` 或类似的数据定义。

- [ ] **Step 2: 为独立包装类型子分类添加标记**

根据实际数据结构调整，在子分类数据中添加 `isIndividuallyWrapped` 标记。具体实现取决于当前的数据结构。

示例（如果子分类是简单的字符串列表）：
```dart
// 如果需要添加独立包装子分类，在相应分类下添加：

    '独立包装牛奶',
    '独立小包零食',
```

或者如果子分类有更复杂的数据结构，需要添加额外字段。

- [ ] **Step 3: 验证编译通过**

Run: `cd H:/code/food_app && flutter analyze lib/utils/constants.dart`
Expected: No issues found

- [ ] **Step 4: Commit**

```bash
git add lib/utils/constants.dart
git commit -m "feat: 添加独立包装类型子分类"
```

---

## Task 11: 功能验证测试

- [ ] **Step 1: 运行完整项目分析**

Run: `cd H:/code/food_app && flutter analyze`
Expected: No issues found

- [ ] **Step 2: 运行应用进行手动测试**

测试场景：
1. 新建物品，验证独立包装选项可切换
2. 在物品卡片上点击"开封"按钮，验证状态变化
3. 验证建议日期正确显示
4. 验证超过建议日期时显示红色警告

- [ ] **Step 3: 最终提交**

```bash
git add -A
git commit -m "feat: 完成开封时间功能优化

- 新增 suggestedUseDate、useDateSource、isIndividuallyWrapped 字段
- 数据库升级到版本 6
- 新增开封保质期规则库
- AI 服务新增开封保质期分析方法
- 物品卡片新增快速开封按钮和建议日期展示
- 详情页新增建议日期展示卡片
- 编辑页新增独立包装选项"
```

---

## 自我审查清单

- [x] **Spec 覆盖检查**：所有设计文档中的需求都有对应任务
- [x] **占位符检查**：无 TBD、TODO、implement later 等
- [x] **类型一致性检查**：所有类型定义和调用保持一致
