# AI录入页面与物品详情页实现计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 改版AI录入页面和物品详情页，实现stitch设计系统的UI规范

**Architecture:** 渐进式改造现有页面，保留业务逻辑，新增UI组件。AI分析采用缓存复用策略降低token消耗。

**Tech Stack:** Flutter, Riverpod, SQLite (sqflite), Dio

---

## 文件结构

### 新建文件
```
lib/
├── models/
│   └── ai_analysis_cache.dart      # AI分析缓存模型
├── widgets/
│   ├── photo_recognition_button.dart  # 大圆形拍照按钮
│   ├── recent_items_list.dart         # 最近物品横向滚动
│   ├── hero_image_section.dart        # 详情页大图区域
│   ├── lifecycle_timeline.dart        # 生命周期时间轴
│   └── ai_analysis_card.dart          # AI保质期分析卡片
```

### 修改文件
```
lib/
├── pages/
│   ├── ai_input_page.dart           # AI录入页面（重构UI）
│   └── item_detail_page.dart        # 物品详情页（重构UI）
├── services/
│   ├── database_service.dart        # 新增：getRecentItems, AI缓存表
│   └── ai_service.dart              # 新增：analyzeShelfLife
├── providers/
│   └── item_provider.dart           # 新增：recentItemsProvider
```

---

## Task 1: 数据层扩展 - 最近物品查询

**Files:**
- Modify: `lib/services/database_service.dart`

- [ ] **Step 1: 添加最近物品查询方法**

在 `DatabaseService` 类中添加方法：

```dart
/// 获取最近添加的物品
Future<List<Item>> getRecentItems({int limit = 5}) async {
  final db = await database;
  final List<Map<String, dynamic>> maps = await db.query(
    tableItems,
    orderBy: 'created_at DESC',
    limit: limit,
  );
  return maps.map((map) => Item.fromJson(map)).toList();
}
```

- [ ] **Step 2: 验证数据库服务编译通过**

Run: `cd H:/code/food_app && flutter analyze lib/services/database_service.dart`
Expected: No issues found

- [ ] **Step 3: 提交数据层变更**

```bash
cd H:/code/food_app && git add lib/services/database_service.dart && git commit -m "feat(db): add getRecentItems method for AI input page"
```

---

## Task 2: Provider层扩展 - 最近物品Provider

**Files:**
- Modify: `lib/providers/item_provider.dart`

- [ ] **Step 1: 添加最近物品Provider**

在 `item_provider.dart` 中添加：

```dart
/// 最近添加的物品Provider
final recentItemsProvider = FutureProvider<List<Item>>((ref) async {
  final dbService = DatabaseService();
  return await dbService.getRecentItems(limit: 5);
});
```

- [ ] **Step 2: 验证Provider编译通过**

Run: `cd H:/code/food_app && flutter analyze lib/providers/item_provider.dart`
Expected: No issues found

- [ ] **Step 3: 提交Provider变更**

```bash
cd H:/code/food_app && git add lib/providers/item_provider.dart && git commit -m "feat(provider): add recentItemsProvider"
```

---

## Task 3: 大圆形拍照按钮组件

**Files:**
- Create: `lib/widgets/photo_recognition_button.dart`

- [ ] **Step 1: 创建PhotoRecognitionButton组件**

```dart
import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import '../theme/spacing.dart';

/// 大圆形拍照识别按钮
class PhotoRecognitionButton extends StatelessWidget {
  final VoidCallback onTap;
  final bool isLoading;

  const PhotoRecognitionButton({
    super.key,
    required this.onTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        width: 224,
        height: 224,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primaryContainer,
              AppColors.primaryFixed,
            ],
          ),
          border: Border.all(
            color: AppColors.surfaceContainerLow,
            width: 6,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF4ADE80).withOpacity(0.6),
              blurRadius: 48,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // 光晕叠加层
            Container(
              width: 224,
              height: 224,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.2),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(),
              ),
            ),
            // 内容
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isLoading)
                  const SizedBox(
                    width: 64,
                    height: 64,
                    child: CircularProgressIndicator(
                      color: AppColors.onPrimaryContainer,
                      strokeWidth: 3,
                    ),
                  )
                else
                  const Icon(
                    Icons.photo_camera,
                    size: 64,
                    color: AppColors.onPrimaryContainer,
                  ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  '拍照识别',
                  style: AppTypography.titleLg.copyWith(
                    color: AppColors.onPrimaryContainer,
                  ),
                ),
                Text(
                  '📸 拍照识别',
                  style: AppTypography.bodySm.copyWith(
                    color: AppColors.onPrimaryContainer.withOpacity(0.8),
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
```

- [ ] **Step 2: 添加必要的import**

在文件顶部添加：
```dart
import 'dart:ui';
```

- [ ] **Step 3: 验证组件编译通过**

Run: `cd H:/code/food_app && flutter analyze lib/widgets/photo_recognition_button.dart`
Expected: No issues found

- [ ] **Step 4: 提交组件**

```bash
cd H:/code/food_app && git add lib/widgets/photo_recognition_button.dart && git commit -m "feat(widget): add PhotoRecognitionButton with green glow effect"
```

---

## Task 4: 最近物品横向滚动组件

**Files:**
- Create: `lib/widgets/recent_items_list.dart`

- [ ] **Step 1: 创建RecentItemsList组件**

```dart
import 'package:flutter/material.dart';
import '../models/item.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import '../theme/spacing.dart';
import '../utils/constants.dart';

/// 最近物品横向滚动列表
class RecentItemsList extends StatelessWidget {
  final List<Item> items;
  final void Function(Item item) onTap;

  const RecentItemsList({
    super.key,
    required this.items,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
          child: Text(
            '最近添加',
            style: AppTypography.labelCaps.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          height: 120,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.containerMargin),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md),
            itemBuilder: (context, index) {
              final item = items[index];
              return _RecentItemCard(item: item, onTap: () => onTap(item));
            },
          ),
        ),
      ],
    );
  }
}

class _RecentItemCard extends StatelessWidget {
  final Item item;
  final VoidCallback onTap;

  const _RecentItemCard({
    required this.item,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final daysRemaining = item.expiryDate.difference(DateTime.now()).inDays;
    final expiryDays = item.expiryDate.difference(item.purchaseDate).inDays;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 140,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.outlineVariant),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  PresetCategories.getIcon(item.category),
                  size: 18,
                  color: AppColors.onSurfaceVariant,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  item.category,
                  style: AppTypography.bodySm.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              item.name,
              style: AppTypography.bodyBase.copyWith(
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: daysRemaining < 0
                    ? AppColors.errorContainer
                    : daysRemaining <= 7
                        ? AppColors.secondaryContainer
                        : AppColors.surfaceContainer,
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
              child: Text(
                '+ $expiryDays 天',
                style: AppTypography.labelCaps.copyWith(
                  fontSize: 10,
                  color: daysRemaining < 0
                      ? AppColors.onErrorContainer
                      : daysRemaining <= 7
                          ? AppColors.onSecondaryContainer
                          : AppColors.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: 验证组件编译通过**

Run: `cd H:/code/food_app && flutter analyze lib/widgets/recent_items_list.dart`
Expected: No issues found

- [ ] **Step 3: 提交组件**

```bash
cd H:/code/food_app && git add lib/widgets/recent_items_list.dart && git commit -m "feat(widget): add RecentItemsList horizontal scroll component"
```

---

## Task 5: 重构AI录入页面

**Files:**
- Modify: `lib/pages/ai_input_page.dart`

- [ ] **Step 1: 重写AI录入页面build方法**

替换 `_AIInputPageState` 的 `build` 方法：

```dart
@override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: AppColors.background,
    body: SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.containerMargin),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 512),
          child: Column(
            children: [
              const SizedBox(height: 100),
              // 标题区域
              _buildHeader(),
              const SizedBox(height: AppSpacing.xl),
              // 拍照按钮
              PhotoRecognitionButton(
                onTap: () => _handlePhotoRecognition(),
                isLoading: _isLoading && _loadingText.contains('识别'),
              ),
              const SizedBox(height: AppSpacing.lg),
              // 语音录入按钮
              _buildVoiceButton(),
              const SizedBox(height: AppSpacing.xl),
              // 最近物品
              _buildRecentItems(),
              const SizedBox(height: AppSpacing.lg),
              // 手动录入
              _buildManualEntryLink(),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    ),
  );
}
```

- [ ] **Step 2: 添加标题区域方法**

```dart
Widget _buildHeader() {
  return Column(
    children: [
      Text(
        '添加物品',
        style: AppTypography.display.copyWith(
          color: AppColors.onSurface,
        ),
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: AppSpacing.xs),
      Text(
        '让AI帮你处理过期日期',
        style: AppTypography.bodyBase.copyWith(
          color: AppColors.onSurfaceVariant,
        ),
        textAlign: TextAlign.center,
      ),
    ],
  );
}
```

- [ ] **Step 3: 添加语音录入按钮方法**

```dart
Widget _buildVoiceButton() {
  return Center(
    child: GestureDetector(
      onTap: _isLoading ? null : _handleVoiceInput,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 320),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(AppRadius.full),
          border: Border.all(
            color: Colors.white.withOpacity(0.5),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.mic,
              color: AppColors.primary,
            ),
            const SizedBox(width: AppSpacing.sm),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '语音录入',
                  style: AppTypography.bodyBase.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '🎤 语音录入',
                  style: AppTypography.bodySm.copyWith(
                    color: AppColors.onSurfaceVariant,
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
```

- [ ] **Step 4: 添加最近物品区域方法**

```dart
Widget _buildRecentItems() {
  final recentItemsAsync = ref.watch(recentItemsProvider);
  
  return recentItemsAsync.when(
    data: (items) => RecentItemsList(
      items: items,
      onTap: (item) => _handleRecentItemTap(item),
    ),
    loading: () => const SizedBox.shrink(),
    error: (_, __) => const SizedBox.shrink(),
  );
}
```

- [ ] **Step 5: 添加手动录入链接方法**

```dart
Widget _buildManualEntryLink() {
  return Center(
    child: GestureDetector(
      onTap: _handleManualInput,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.edit_square,
            size: 18,
            color: AppColors.onSurfaceVariant,
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            '手动录入',
            style: AppTypography.bodySm.copyWith(
              color: AppColors.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    ),
  );
}
```

- [ ] **Step 6: 添加最近物品点击处理**

```dart
void _handleRecentItemTap(Item item) {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (context) => ItemEditPage(
        prefilledData: PrefilledData(
          name: item.name,
          category: item.category,
          subCategory: item.subCategory,
          brand: item.brand,
          specification: item.specification,
          expiryDate: item.expiryDate,
          purchaseDate: DateTime.now(),
        ),
      ),
    ),
  );
}
```

- [ ] **Step 7: 更新import**

在文件顶部添加必要的import：
```dart
import '../widgets/photo_recognition_button.dart';
import '../widgets/recent_items_list.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
```

确保类声明为 `ConsumerStatefulWidget` 和 `ConsumerState`。

- [ ] **Step 8: 验证页面编译通过**

Run: `cd H:/code/food_app && flutter analyze lib/pages/ai_input_page.dart`
Expected: No issues found

- [ ] **Step 9: 提交AI录入页面重构**

```bash
cd H:/code/food_app && git add lib/pages/ai_input_page.dart && git commit -m "refactor(ai-input): redesign UI with centered photo button and recent items"
```

---

## Task 6: Hero大图区域组件

**Files:**
- Create: `lib/widgets/hero_image_section.dart`

- [ ] **Step 1: 创建HeroImageSection组件**

```dart
import 'package:flutter/material.dart';
import '../models/item.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../utils/constants.dart';
import 'status_badge.dart';

/// Hero大图区域
class HeroImageSection extends StatelessWidget {
  final Item item;
  final int daysRemaining;

  const HeroImageSection({
    super.key,
    required this.item,
    required this.daysRemaining,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 512),
      child: AspectRatio(
        aspectRatio: 1.0,
        child: Container(
          margin: const EdgeInsets.all(AppSpacing.containerMargin),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border: Border.all(
              color: AppColors.outlineVariant.withOpacity(0.3),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              // 图片或图标
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.xl),
                child: item.imageUrl != null
                    ? Image.network(
                        item.imageUrl!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                        errorBuilder: (_, __, ___) => _buildPlaceholder(),
                      )
                    : _buildPlaceholder(),
              ),
              // 状态徽章
              Positioned(
                top: AppSpacing.md,
                left: AppSpacing.md,
                child: _buildStatusBadge(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: AppColors.surfaceVariant,
      child: Center(
        child: Icon(
          PresetCategories.getIcon(item.category),
          size: 64,
          color: AppColors.primary.withOpacity(0.5),
        ),
      ),
    );
  }

  Widget _buildStatusBadge() {
    String text;
    Color bgColor;
    Color textColor;
    IconData icon;

    if (daysRemaining < 0) {
      text = '已过期 ${-daysRemaining} 天';
      bgColor = AppColors.errorContainer;
      textColor = AppColors.onErrorContainer;
      icon = Icons.warning;
    } else if (daysRemaining <= 3) {
      text = '还有 $daysRemaining 天过期';
      bgColor = AppColors.errorContainer;
      textColor = AppColors.onErrorContainer;
      icon = Icons.warning;
    } else if (daysRemaining <= 7) {
      text = '还有 $daysRemaining 天过期';
      bgColor = AppColors.secondaryContainer;
      textColor = AppColors.onSecondaryContainer;
      icon = Icons.schedule;
    } else {
      text = '正常';
      bgColor = AppColors.primaryContainer;
      textColor = AppColors.onPrimaryContainer;
      icon = Icons.check_circle;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppRadius.full),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 4,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: textColor),
          const SizedBox(width: AppSpacing.xs),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.05,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: 验证组件编译通过**

Run: `cd H:/code/food_app && flutter analyze lib/widgets/hero_image_section.dart`
Expected: No issues found

- [ ] **Step 3: 提交组件**

```bash
cd H:/code/food_app && git add lib/widgets/hero_image_section.dart && git commit -m "feat(widget): add HeroImageSection with status badge overlay"
```

---

## Task 7: 生命周期时间轴组件

**Files:**
- Create: `lib/widgets/lifecycle_timeline.dart`

- [ ] **Step 1: 创建LifecycleTimeline组件**

```dart
import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import '../theme/spacing.dart';

/// 生命周期时间轴
class LifecycleTimeline extends StatelessWidget {
  final DateTime purchaseDate;
  final DateTime expiryDate;
  final int daysRemaining;

  const LifecycleTimeline({
    super.key,
    required this.purchaseDate,
    required this.expiryDate,
    required this.daysRemaining,
  });

  @override
  Widget build(BuildContext context) {
    final totalDays = expiryDate.difference(purchaseDate).inDays;
    final elapsedDays = DateTime.now().difference(purchaseDate).inDays;
    final progress = totalDays > 0 ? (elapsedDays / totalDays).clamp(0.0, 1.0) : 1.0;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.timeline,
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                '生命周期',
                style: AppTypography.titleLg.copyWith(
                  color: AppColors.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          _buildProgressBar(progress),
          const SizedBox(height: AppSpacing.lg),
          _buildMarkers(),
        ],
      ),
    );
  }

  Widget _buildProgressBar(double progress) {
    final progressColor = _getProgressColor(progress);
    
    return Stack(
      children: [
        // 背景轨道
        Container(
          height: 12,
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(AppRadius.full),
          ),
        ),
        // 进度填充
        FractionallySizedBox(
          widthFactor: progress,
          child: Container(
            height: 12,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary,
                  progressColor,
                ],
              ),
              borderRadius: BorderRadius.circular(AppRadius.full),
            ),
          ),
        ),
      ],
    );
  }

  Color _getProgressColor(double progress) {
    if (progress >= 0.8) return AppColors.error;
    if (progress >= 0.5) return AppColors.secondary;
    return AppColors.primary;
  }

  Widget _buildMarkers() {
    return Stack(
      children: [
        // 购买日期
        Positioned(
          left: 0,
          child: _buildMarker(
            _formatDate(purchaseDate),
            '购买',
            AppColors.outlineVariant,
          ),
        ),
        // 今天
        Positioned(
          left: 0,
          right: 0,
          child: Center(
            child: _buildMarker(
              '今天',
              '',
              daysRemaining < 0 ? AppColors.error : AppColors.primary,
              isToday: true,
            ),
          ),
        ),
        // 过期日期
        Positioned(
          right: 0,
          child: _buildMarker(
            _formatDate(expiryDate),
            '过期',
            AppColors.outlineVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildMarker(String text, String label, Color color, {bool isToday = false}) {
    return Column(
      children: [
        Container(
          width: isToday ? 12 : 4,
          height: isToday ? 12 : 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        if (label.isNotEmpty)
          Text(
            label,
            style: AppTypography.labelCaps.copyWith(
              color: AppColors.onSurfaceVariant,
              fontSize: 10,
            ),
          ),
        Text(
          text,
          style: AppTypography.labelCaps.copyWith(
            color: isToday ? color : AppColors.onSurfaceVariant,
            fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}';
  }
}
```

- [ ] **Step 2: 验证组件编译通过**

Run: `cd H:/code/food_app && flutter analyze lib/widgets/lifecycle_timeline.dart`
Expected: No issues found

- [ ] **Step 3: 提交组件**

```bash
cd H:/code/food_app && git add lib/widgets/lifecycle_timeline.dart && git commit -m "feat(widget): add LifecycleTimeline progress bar component"
```

---

## Task 8: AI分析缓存模型

**Files:**
- Create: `lib/models/ai_analysis_cache.dart`

- [ ] **Step 1: 创建AI分析缓存模型**

```dart
/// AI保质期分析缓存
class AIAnalysisCache {
  final String id;
  final String cacheKey;      // 分类_子分类_开封状态
  final String analysisText;  // AI分析结果
  final DateTime createdAt;   // 创建时间

  const AIAnalysisCache({
    required this.id,
    required this.cacheKey,
    required this.analysisText,
    required this.createdAt,
  });

  /// 生成缓存Key
  static String generateKey(String category, String? subCategory, bool isOpened) {
    final parts = [category];
    if (subCategory != null && subCategory.isNotEmpty) {
      parts.add(subCategory);
    }
    parts.add(isOpened ? '已开封' : '未开封');
    return parts.join('_');
  }

  /// 从JSON创建
  factory AIAnalysisCache.fromJson(Map<String, dynamic> json) {
    return AIAnalysisCache(
      id: json['id'] as String,
      cacheKey: json['cache_key'] as String,
      analysisText: json['analysis_text'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'cache_key': cacheKey,
      'analysis_text': analysisText,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// 复制并修改
  AIAnalysisCache copyWith({
    String? id,
    String? cacheKey,
    String? analysisText,
    DateTime? createdAt,
  }) {
    return AIAnalysisCache(
      id: id ?? this.id,
      cacheKey: cacheKey ?? this.cacheKey,
      analysisText: analysisText ?? this.analysisText,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
```

- [ ] **Step 2: 验证模型编译通过**

Run: `cd H:/code/food_app && flutter analyze lib/models/ai_analysis_cache.dart`
Expected: No issues found

- [ ] **Step 3: 提交模型**

```bash
cd H:/code/food_app && git add lib/models/ai_analysis_cache.dart && git commit -m "feat(model): add AIAnalysisCache for shelf-life analysis caching"
```

---

## Task 9: 数据库扩展 - AI分析缓存表

**Files:**
- Modify: `lib/services/database_service.dart`

- [ ] **Step 1: 添加表名常量**

在 `DatabaseService` 类中添加：

```dart
static const String tableAIAnalysisCache = 'ai_analysis_cache';
```

- [ ] **Step 2: 在_onCreate中创建表**

在 `_onCreate` 方法末尾添加：

```dart
// AI分析缓存表
await db.execute('''
  CREATE TABLE $tableAIAnalysisCache (
    id TEXT PRIMARY KEY,
    cache_key TEXT NOT NULL UNIQUE,
    analysis_text TEXT NOT NULL,
    created_at TEXT NOT NULL
  )
''');

// 创建索引
await db.execute('CREATE INDEX idx_ai_analysis_cache_key ON $tableAIAnalysisCache (cache_key)');
```

- [ ] **Step 3: 升级数据库版本**

将 `_databaseVersion` 从 4 改为 5，并在 `_onUpgrade` 中添加：

```dart
// 版本4到版本5：添加AI分析缓存表
if (oldVersion < 5) {
  await db.execute('''
    CREATE TABLE IF NOT EXISTS $tableAIAnalysisCache (
      id TEXT PRIMARY KEY,
      cache_key TEXT NOT NULL UNIQUE,
      analysis_text TEXT NOT NULL,
      created_at TEXT NOT NULL
    )
  ''');
  await db.execute('CREATE INDEX IF NOT EXISTS idx_ai_analysis_cache_key ON $tableAIAnalysisCache (cache_key)');
}
```

- [ ] **Step 4: 添加缓存操作方法**

```dart
// ==================== AI分析缓存操作 ====================

/// 获取AI分析缓存
Future<AIAnalysisCache?> getAIAnalysisCache(String cacheKey) async {
  final db = await database;
  final List<Map<String, dynamic>> maps = await db.query(
    tableAIAnalysisCache,
    where: 'cache_key = ?',
    whereArgs: [cacheKey],
    limit: 1,
  );
  if (maps.isEmpty) return null;
  return AIAnalysisCache.fromJson(maps.first);
}

/// 保存AI分析缓存
Future<void> saveAIAnalysisCache(AIAnalysisCache cache) async {
  final db = await database;
  await db.insert(
    tableAIAnalysisCache,
    cache.toJson(),
    conflictAlgorithm: ConflictAlgorithm.replace,
  );
}

/// 清除过期的AI分析缓存（超过30天）
Future<void> clearExpiredAIAnalysisCache() async {
  final db = await database;
  final expiryDate = DateTime.now().subtract(const Duration(days: 30));
  await db.delete(
    tableAIAnalysisCache,
    where: 'created_at < ?',
    whereArgs: [expiryDate.toIso8601String()],
  );
}
```

- [ ] **Step 5: 添加import**

在文件顶部添加：
```dart
import '../models/ai_analysis_cache.dart';
```

- [ ] **Step 6: 验证数据库服务编译通过**

Run: `cd H:/code/food_app && flutter analyze lib/services/database_service.dart`
Expected: No issues found

- [ ] **Step 7: 提交数据库扩展**

```bash
cd H:/code/food_app && git add lib/services/database_service.dart && git commit -m "feat(db): add AI analysis cache table and methods"
```

---

## Task 10: AI服务扩展 - 保质期分析

**Files:**
- Modify: `lib/services/ai_service.dart`

- [ ] **Step 1: 添加保质期分析方法**

在 `AIService` 类中添加：

```dart
/// 保质期分析结果
class ShelfLifeAnalysis {
  final String analysis;
  final double confidence;

  const ShelfLifeAnalysis({
    required this.analysis,
    required this.confidence,
  });
}

/// 分析物品保质期
Future<ShelfLifeAnalysis> analyzeShelfLife({
  required AIConfig config,
  required String name,
  required String category,
  String? subCategory,
  required bool isOpened,
  required int daysRemaining,
}) async {
  final prompt = _getShelfLifePrompt(
    name: name,
    category: category,
    subCategory: subCategory,
    isOpened: isOpened,
    daysRemaining: daysRemaining,
  );

  try {
    final response = await _callTextAPI(
      config: config,
      prompt: prompt,
    );

    String? content;
    if (response['choices'] != null) {
      content = response['choices'][0]['message']['content'] as String?;
    }

    if (content == null) {
      throw Exception('AI响应内容为空');
    }

    return ShelfLifeAnalysis(
      analysis: content.trim(),
      confidence: 0.85,
    );
  } catch (e) {
    throw _handleError(e);
  }
}

/// 保质期分析提示词
String _getShelfLifePrompt({
  required String name,
  required String category,
  String? subCategory,
  required bool isOpened,
  required int daysRemaining,
}) {
  final today = DateTime.now().toString().split(' ')[0];
  final openStatus = isOpened ? '已开封' : '未开封';
  
  return '''
你是一个物品保质期分析专家。请根据以下信息，给出简短的保质期建议。

【物品信息】
- 名称：$name
- 分类：$category${subCategory != null ? ' ($subCategory)' : ''}
- 状态：$openStatus
- 剩余天数：$daysRemaining 天

【分析要求】
1. 如果已开封，说明开封后的保质期变化
2. 给出存储建议（温度、位置等）
3. 提醒食用/使用优先级
4. 字数控制在100字以内

【返回格式】
直接返回分析文本，不要添加标题或格式。

今天日期：$today
''';
}
```

- [ ] **Step 2: 验证AI服务编译通过**

Run: `cd H:/code/food_app && flutter analyze lib/services/ai_service.dart`
Expected: No issues found

- [ ] **Step 3: 提交AI服务扩展**

```bash
cd H:/code/food_app && git add lib/services/ai_service.dart && git commit -m "feat(ai): add analyzeShelfLife method with caching support"
```

---

## Task 11: AI保质期分析卡片组件

**Files:**
- Create: `lib/widgets/ai_analysis_card.dart`

- [ ] **Step 1: 创建AIAnalysisCard组件**

```dart
import 'package:flutter/material.dart';
import '../models/item.dart';
import '../models/ai_config.dart';
import '../models/ai_analysis_cache.dart';
import '../services/ai_service.dart';
import '../services/database_service.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import '../theme/spacing.dart';

/// AI保质期分析卡片
class AIAnalysisCard extends StatefulWidget {
  final Item item;
  final AIConfig? aiConfig;

  const AIAnalysisCard({
    super.key,
    required this.item,
    this.aiConfig,
  });

  @override
  State<AIAnalysisCard> createState() => _AIAnalysisCardState();
}

class _AIAnalysisCardState extends State<AIAnalysisCard> {
  String? _analysis;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAnalysis();
  }

  Future<void> _loadAnalysis() async {
    final cacheKey = AIAnalysisCache.generateKey(
      widget.item.category,
      widget.item.subCategory,
      widget.item.openedDate != null,
    );

    // 先查缓存
    final dbService = DatabaseService();
    final cached = await dbService.getAIAnalysisCache(cacheKey);
    
    if (cached != null) {
      setState(() {
        _analysis = cached.analysisText;
      });
      return;
    }

    // 没有缓存，检查是否有AI配置
    if (widget.aiConfig == null) {
      setState(() {
        _analysis = _getDefaultAnalysis();
      });
      return;
    }

    // 调用AI
    setState(() {
      _isLoading = true;
    });

    try {
      final aiService = AIService();
      final daysRemaining = widget.item.expiryDate.difference(DateTime.now()).inDays;
      
      final result = await aiService.analyzeShelfLife(
        config: widget.aiConfig!,
        name: widget.item.name,
        category: widget.item.category,
        subCategory: widget.item.subCategory,
        isOpened: widget.item.openedDate != null,
        daysRemaining: daysRemaining,
      );

      // 保存缓存
      final cache = AIAnalysisCache(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        cacheKey: cacheKey,
        analysisText: result.analysis,
        createdAt: DateTime.now(),
      );
      await dbService.saveAIAnalysisCache(cache);

      setState(() {
        _analysis = result.analysis;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _analysis = _getDefaultAnalysis();
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  String _getDefaultAnalysis() {
    final isOpened = widget.item.openedDate != null;
    final daysRemaining = widget.item.expiryDate.difference(DateTime.now()).inDays;
    
    if (daysRemaining < 0) {
      return '此物品已过期，建议不要继续使用。';
    }
    
    String tip = '';
    if (widget.item.category == '食品') {
      tip = isOpened 
          ? '开封后请尽快食用，建议冷藏保存。'
          : '请按照包装说明妥善保存，注意保质期。';
    } else if (widget.item.category == '药品') {
      tip = isOpened
          ? '开封后保质期可能缩短，请参照药品说明书。'
          : '请置于阴凉干燥处保存，避免阳光直射。';
    } else {
      tip = '请按照产品说明妥善保存。';
    }
    
    if (daysRemaining <= 3) {
      tip += ' 剩余天数较少，建议优先使用。';
    }
    
    return tip;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.2),
        ),
      ),
      child: Stack(
        children: [
          // 右上角光晕装饰
          Positioned(
            top: -16,
            right: -16,
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withOpacity(0.1),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(),
              ),
            ),
          ),
          // 内容
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 图标
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primaryContainer,
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: AppColors.onPrimaryContainer,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              // 文字
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI保质期分析',
                      style: AppTypography.titleLg.copyWith(
                        color: AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    if (_isLoading)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            SizedBox(width: AppSpacing.sm),
                            Text('正在分析...'),
                          ],
                        ),
                      )
                    else
                      Text(
                        _analysis ?? '',
                        style: AppTypography.bodyBase.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: 添加必要的import**

在文件顶部添加：
```dart
import 'dart:ui';
```

- [ ] **Step 3: 验证组件编译通过**

Run: `cd H:/code/food_app && flutter analyze lib/widgets/ai_analysis_card.dart`
Expected: No issues found

- [ ] **Step 4: 提交组件**

```bash
cd H:/code/food_app && git add lib/widgets/ai_analysis_card.dart && git commit -m "feat(widget): add AIAnalysisCard with caching support"
```

---

## Task 12: 重构物品详情页

**Files:**
- Modify: `lib/pages/item_detail_page.dart`

- [ ] **Step 1: 重写build方法主体结构**

替换 `_buildContent` 方法，使用新组件：

```dart
Widget _buildContent(BuildContext context, WidgetRef ref, Item item) {
  final daysRemaining = app_utils.DateUtils.daysRemaining(item.expiryDate);

  return Stack(
    children: [
      SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero大图区域
            HeroImageSection(item: item, daysRemaining: daysRemaining),
            
            // 标题区域
            _buildTitleSection(item),
            
            // 生命周期时间轴
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.containerMargin),
              child: LifecycleTimeline(
                purchaseDate: item.purchaseDate,
                expiryDate: item.expiryDate,
                daysRemaining: daysRemaining,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            
            // AI保质期分析
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.containerMargin),
              child: Consumer(
                builder: (context, ref, _) {
                  final configAsync = ref.watch(defaultAIConfigProvider);
                  return configAsync.when(
                    data: (config) => AIAnalysisCard(item: item, aiConfig: config),
                    loading: () => AIAnalysisCard(item: item),
                    error: (_, __) => AIAnalysisCard(item: item),
                  );
                },
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
      
      // 底部操作栏
      Positioned(
        left: 0,
        right: 0,
        bottom: 0,
        child: _buildBottomActionBar(context, ref, item),
      ),
    ],
  );
}
```

- [ ] **Step 2: 添加标题区域方法**

```dart
Widget _buildTitleSection(Item item) {
  final daysRemaining = app_utils.DateUtils.daysRemaining(item.expiryDate);
  final statusText = item.openedDate != null ? '已开封' : '未开封';
  final subtitle = '${item.category}${item.specification != null ? ' • ${item.specification}' : ''} • $statusText';

  return Padding(
    padding: const EdgeInsets.all(AppSpacing.containerMargin),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          item.name,
          style: AppTypography.display.copyWith(
            color: AppColors.onSurface,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          subtitle,
          style: AppTypography.bodyBase.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
      ],
    ),
  );
}
```

- [ ] **Step 3: 更新底部操作栏样式**

修改 `_buildBottomActionBar` 方法：

```dart
Widget _buildBottomActionBar(BuildContext context, WidgetRef ref, Item item) {
  final isDisabled = item.status == ItemStatus.consumed || item.quantity <= 0;

  return Container(
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: BoxDecoration(
      color: AppColors.surface.withOpacity(0.95),
      border: Border(
        top: BorderSide(color: AppColors.surfaceVariant),
      ),
    ),
    child: SafeArea(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 512),
        child: Row(
          children: [
            // 编辑按钮
            _buildSquareButton(
              icon: Icons.edit_outlined,
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => ItemEditPage(itemId: item.id),
                  ),
                );
              },
            ),
            const SizedBox(width: AppSpacing.sm),
            // 删除按钮
            _buildSquareButton(
              icon: Icons.delete_outline,
              isDestructive: true,
              onPressed: () => _showDeleteConfirmDialog(context, ref),
            ),
            const SizedBox(width: AppSpacing.md),
            // 主操作按钮
            Expanded(
              child: _buildPrimaryButton(
                context: context,
                ref: ref,
                item: item,
                isDisabled: isDisabled,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Widget _buildSquareButton({
  required IconData icon,
  bool isDestructive = false,
  VoidCallback? onPressed,
}) {
  return GestureDetector(
    onTap: onPressed,
    child: Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: isDestructive
            ? AppColors.errorContainer.withOpacity(0.3)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: isDestructive
              ? AppColors.error.withOpacity(0.3)
              : AppColors.outlineVariant.withOpacity(0.3),
        ),
      ),
      child: Icon(
        icon,
        color: isDestructive ? AppColors.error : AppColors.onSurface,
      ),
    ),
  );
}

Widget _buildPrimaryButton({
  required BuildContext context,
  required WidgetRef ref,
  required Item item,
  required bool isDisabled,
}) {
  return GestureDetector(
    onTap: isDisabled ? null : () => _consumeOne(context, ref, item),
    child: Container(
      height: 48,
      decoration: BoxDecoration(
        color: isDisabled ? AppColors.surfaceContainer : AppColors.primary,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle,
            color: isDisabled ? AppColors.onSurfaceVariant : AppColors.onPrimary,
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            '标记已用',
            style: AppTypography.titleLg.copyWith(
              color: isDisabled ? AppColors.onSurfaceVariant : AppColors.onPrimary,
            ),
          ),
        ],
      ),
    ),
  );
}
```

- [ ] **Step 4: 更新import**

在文件顶部添加：
```dart
import '../widgets/hero_image_section.dart';
import '../widgets/lifecycle_timeline.dart';
import '../widgets/ai_analysis_card.dart';
```

- [ ] **Step 5: 验证页面编译通过**

Run: `cd H:/code/food_app && flutter analyze lib/pages/item_detail_page.dart`
Expected: No issues found

- [ ] **Step 6: 提交物品详情页重构**

```bash
cd H:/code/food_app && git add lib/pages/item_detail_page.dart && git commit -m "refactor(item-detail): redesign UI with hero image, timeline, and AI analysis"
```

---

## Task 13: 添加默认AI配置Provider

**Files:**
- Modify: `lib/providers/item_provider.dart`

- [ ] **Step 1: 添加defaultAIConfigProvider**

在 `item_provider.dart` 中添加：

```dart
/// 默认AI配置Provider
final defaultAIConfigProvider = FutureProvider<AIConfig?>((ref) async {
  final dbService = DatabaseService();
  return await dbService.getAIConfig();
});
```

- [ ] **Step 2: 添加必要的import**

```dart
import '../models/ai_config.dart';
```

- [ ] **Step 3: 验证Provider编译通过**

Run: `cd H:/code/food_app && flutter analyze lib/providers/item_provider.dart`
Expected: No issues found

- [ ] **Step 4: 提交Provider扩展**

```bash
cd H:/code/food_app && git add lib/providers/item_provider.dart && git commit -m "feat(provider): add defaultAIConfigProvider"
```

---

## Task 14: 最终验证与测试

- [ ] **Step 1: 运行Flutter analyze检查全部代码**

Run: `cd H:/code/food_app && flutter analyze`
Expected: No issues found

- [ ] **Step 2: 尝试构建APK验证**

Run: `cd H:/code/food_app && flutter build apk --debug`
Expected: Build successful

- [ ] **Step 3: 提交最终变更**

```bash
cd H:/code/food_app && git add -A && git commit -m "feat(ui): complete AI input and item detail pages redesign

- AI录入页面：大圆形拍照按钮、语音录入、最近物品横向滚动
- 物品详情页：Hero大图、时间轴进度条、AI保质期分析卡片
- 新增组件：PhotoRecognitionButton, RecentItemsList, HeroImageSection, LifecycleTimeline, AIAnalysisCard
- AI分析缓存支持，降低token消耗"
```

---

## 验收检查清单

### AI录入页面
- [ ] 拍照按钮居中显示，带有绿色光晕阴影
- [ ] 语音录入按钮显示正常
- [ ] 最近物品横向滚动，点击可快速复制录入
- [ ] 手动录入链接可点击
- [ ] 所有文字为中文

### 物品详情页
- [ ] Hero大图区域显示正确，状态徽章叠加在左上角
- [ ] 生命周期时间轴显示购买/今天/过期三个节点
- [ ] AI保质期分析卡片显示，带光晕装饰
- [ ] 底部操作栏固定，毛玻璃效果
- [ ] 所有文字为中文
