# 物品部分消耗功能实现计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 为物品管理应用添加部分消耗功能，允许用户选择消耗数量而非一次性标记全部使用完毕。

**Architecture:** 在现有数据层新增消耗方法，创建两个可复用的 UI 组件（数量选择器、消耗面板），修改详情页和提醒页的底部操作栏。

**Tech Stack:** Flutter, Riverpod, SQLite (sqflite)

---

## 文件结构

```
lib/
├── widgets/
│   ├── quantity_selector.dart      # 新增：数量选择器组件
│   └── consume_bottom_sheet.dart   # 新增：消耗面板组件
├── providers/
│   └── item_provider.dart          # 修改：新增 consumeItem 方法
├── services/
│   └── database_service.dart       # 修改：新增 updateItemQuantity 方法
└── pages/
    ├── item_detail_page.dart       # 修改：改造底部操作栏
    └── reminder_center_page.dart   # 修改：改造任务卡片按钮
```

---

### Task 1: DatabaseService - 新增更新数量方法

**Files:**
- Modify: `lib/services/database_service.dart`

- [ ] **Step 1: 添加 updateItemQuantity 方法**

在 `lib/services/database_service.dart` 文件的 `deleteItem` 方法后面（约第 353 行），添加以下方法：

```dart
  /// 更新物品数量
  Future<void> updateItemQuantity(String id, int quantity) async {
    final db = await database;
    await db.update(
      tableItems,
      {
        'quantity': quantity,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }
```

- [ ] **Step 2: 验证编译通过**

运行: `cd H:/code/food_app && flutter analyze lib/services/database_service.dart`

预期: No issues found

---

### Task 2: ItemProvider - 新增消耗物品方法

**Files:**
- Modify: `lib/providers/item_provider.dart`

- [ ] **Step 1: 添加 consumeItem 方法**

在 `lib/providers/item_provider.dart` 文件的 `markAsConsumed` 方法后面（约第 261 行），添加以下方法：

```dart
  /// 消耗物品（支持部分消耗）
  /// quantity: 消耗数量，默认为 1
  Future<void> consumeItem(String id, {int quantity = 1}) async {
    try {
      final item = state.items.where((i) => i.id == id).firstOrNull;
      if (item == null) return;

      final newQuantity = item.quantity - quantity;

      if (newQuantity <= 0) {
        // 数量归零，标记为已消耗
        await markAsConsumed(id);
      } else {
        // 更新剩余数量
        await _dbService.updateItemQuantity(id, newQuantity);
        await loadItems();
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
```

- [ ] **Step 2: 验证编译通过**

运行: `cd H:/code/food_app && flutter analyze lib/providers/item_provider.dart`

预期: No issues found

---

### Task 3: QuantitySelector - 数量选择器组件

**Files:**
- Create: `lib/widgets/quantity_selector.dart`

- [ ] **Step 1: 创建 QuantitySelector 组件**

创建文件 `lib/widgets/quantity_selector.dart`，内容如下：

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import '../theme/spacing.dart';

/// 数量选择器组件
class QuantitySelector extends StatefulWidget {
  /// 初始值
  final int initialValue;
  
  /// 最大值
  final int maxValue;
  
  /// 最小值
  final int minValue;
  
  /// 单位
  final String unit;
  
  /// 值变化回调
  final ValueChanged<int>? onChanged;

  const QuantitySelector({
    super.key,
    this.initialValue = 1,
    required this.maxValue,
    this.minValue = 1,
    this.unit = '个',
    this.onChanged,
  });

  @override
  State<QuantitySelector> createState() => _QuantitySelectorState();
}

class _QuantitySelectorState extends State<QuantitySelector> {
  late TextEditingController _controller;
  late int _currentValue;

  @override
  void initState() {
    super.initState();
    _currentValue = widget.initialValue.clamp(widget.minValue, widget.maxValue);
    _controller = TextEditingController(text: _currentValue.toString());
  }

  @override
  void didUpdateWidget(QuantitySelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.maxValue != widget.maxValue) {
      // 最大值变化时，确保当前值在有效范围内
      _currentValue = _currentValue.clamp(widget.minValue, widget.maxValue);
      _controller.text = _currentValue.toString();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _decrement() {
    if (_currentValue > widget.minValue) {
      _updateValue(_currentValue - 1);
    }
  }

  void _increment() {
    if (_currentValue < widget.maxValue) {
      _updateValue(_currentValue + 1);
    }
  }

  void _updateValue(int newValue) {
    final clampedValue = newValue.clamp(widget.minValue, widget.maxValue);
    if (clampedValue != _currentValue) {
      setState(() {
        _currentValue = clampedValue;
        _controller.text = _currentValue.toString();
      });
      widget.onChanged?.call(_currentValue);
    }
  }

  void _onSubmitted(String value) {
    final parsed = int.tryParse(value);
    if (parsed != null) {
      _updateValue(parsed);
    } else {
      // 恢复为当前值
      _controller.text = _currentValue.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    final canDecrement = _currentValue > widget.minValue;
    final canIncrement = _currentValue < widget.maxValue;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 减少按钮
        _buildButton(
          icon: Icons.remove,
          onPressed: canDecrement ? _decrement : null,
        ),
        const SizedBox(width: AppSpacing.sm),
        
        // 数量输入框
        SizedBox(
          width: 60,
          child: TextField(
            controller: _controller,
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
            ],
            onSubmitted: _onSubmitted,
            style: AppTypography.titleLg.copyWith(
              color: AppColors.onSurface,
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: AppRadius.medium,
                borderSide: BorderSide(color: AppColors.outlineVariant),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: AppRadius.medium,
                borderSide: BorderSide(color: AppColors.outlineVariant),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: AppRadius.medium,
                borderSide: BorderSide(color: AppColors.primary, width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.sm,
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        
        // 增加按钮
        _buildButton(
          icon: Icons.add,
          onPressed: canIncrement ? _increment : null,
        ),
        const SizedBox(width: AppSpacing.md),
        
        // 单位
        Text(
          widget.unit,
          style: AppTypography.bodyBase.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildButton({
    required IconData icon,
    required VoidCallback? onPressed,
  }) {
    final isEnabled = onPressed != null;
    return Material(
      color: isEnabled ? AppColors.surfaceContainer : AppColors.surfaceContainerHighest,
      borderRadius: AppRadius.medium,
      child: InkWell(
        onTap: onPressed,
        borderRadius: AppRadius.medium,
        child: Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          child: Icon(
            icon,
            size: 20,
            color: isEnabled ? AppColors.onSurface : AppColors.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: 验证编译通过**

运行: `cd H:/code/food_app && flutter analyze lib/widgets/quantity_selector.dart`

预期: No issues found

---

### Task 4: ConsumeBottomSheet - 消耗面板组件

**Files:**
- Create: `lib/widgets/consume_bottom_sheet.dart`

- [ ] **Step 1: 创建 ConsumeBottomSheet 组件**

创建文件 `lib/widgets/consume_bottom_sheet.dart`，内容如下：

```dart
import 'package:flutter/material.dart';
import '../models/item.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import '../theme/spacing.dart';
import 'quantity_selector.dart';

/// 消耗面板回调
typedef ConsumeCallback = void Function(int quantity);

/// 消耗面板底部弹出组件
class ConsumeBottomSheet extends StatefulWidget {
  /// 物品信息
  final Item item;
  
  /// 确认消耗回调
  final ConsumeCallback onConfirm;

  const ConsumeBottomSheet({
    super.key,
    required this.item,
    required this.onConfirm,
  });

  /// 显示消耗面板
  static Future<void> show({
    required BuildContext context,
    required Item item,
    required ConsumeCallback onConfirm,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ConsumeBottomSheet(
        item: item,
        onConfirm: onConfirm,
      ),
    );
  }

  @override
  State<ConsumeBottomSheet> createState() => _ConsumeBottomSheetState();
}

class _ConsumeBottomSheetState extends State<ConsumeBottomSheet> {
  late int _quantity;

  @override
  void initState() {
    super.initState();
    _quantity = 1;
  }

  void _onQuantityChanged(int value) {
    setState(() {
      _quantity = value;
    });
  }

  void _onConfirm() {
    Navigator.pop(context);
    widget.onConfirm(_quantity);
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.lg),
        ),
      ),
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 顶部拖动条
          Container(
            margin: const EdgeInsets.only(top: AppSpacing.sm),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // 标题栏
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                Text(
                  '消耗数量',
                  style: AppTypography.titleLg.copyWith(
                    color: AppColors.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Icon(
                    Icons.close,
                    size: 24,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          
          const Divider(height: 1),
          
          // 物品信息和数量选择
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 物品名称和剩余数量
                Text(
                  '${widget.item.name}（剩余 ${widget.item.quantity} ${widget.item.unit}）',
                  style: AppTypography.bodyBase.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                
                // 数量选择器
                Center(
                  child: QuantitySelector(
                    initialValue: 1,
                    maxValue: widget.item.quantity,
                    minValue: 1,
                    unit: widget.item.unit,
                    onChanged: _onQuantityChanged,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: AppSpacing.md),
          
          // 确认按钮
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _quantity > 0 ? _onConfirm : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.onPrimary,
                  disabledBackgroundColor: AppColors.surfaceContainer,
                  disabledForegroundColor: AppColors.onSurfaceVariant,
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  shape: RoundedRectangleBorder(
                    borderRadius: AppRadius.medium,
                  ),
                ),
                child: const Text('确认消耗'),
              ),
            ),
          ),
          
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: 验证编译通过**

运行: `cd H:/code/food_app && flutter analyze lib/widgets/consume_bottom_sheet.dart`

预期: No issues found

---

### Task 5: ItemDetailPage - 改造底部操作栏

**Files:**
- Modify: `lib/pages/item_detail_page.dart`

- [ ] **Step 1: 添加 import 语句**

在 `lib/pages/item_detail_page.dart` 文件顶部，添加导入：

```dart
import '../widgets/consume_bottom_sheet.dart';
```

在现有的 import 区域（约第 12 行后）添加。

- [ ] **Step 2: 修改底部操作栏**

找到 `_buildBottomActionBar` 方法（约第 366 行），替换为以下代码：

```dart
  /// 构建底部操作栏
  Widget _buildBottomActionBar(BuildContext context, WidgetRef ref, Item item) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.95),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // 编辑按钮
            _buildActionButton(
              icon: Icons.edit_outlined,
              label: '编辑',
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
            _buildActionButton(
              icon: Icons.delete_outline,
              label: '删除',
              isDestructive: true,
              onPressed: () => _showDeleteConfirmDialog(context, ref),
            ),
            const SizedBox(width: AppSpacing.md),
            // 使用1个按钮（快捷按钮）
            Expanded(
              child: ElevatedButton.icon(
                onPressed: item.status == ItemStatus.consumed || item.quantity <= 0
                    ? null
                    : () => _consumeOne(context, ref, item),
                icon: const Icon(Icons.remove_circle_outline),
                label: const Text('使用1个'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.onPrimary,
                  disabledBackgroundColor: AppColors.surfaceContainer,
                  disabledForegroundColor: AppColors.onSurfaceVariant,
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  shape: RoundedRectangleBorder(
                    borderRadius: AppRadius.medium,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            // 更多按钮
            _buildActionButton(
              icon: Icons.more_horiz,
              label: '更多',
              onPressed: item.status == ItemStatus.consumed || item.quantity <= 0
                  ? null
                  : () => _showConsumeBottomSheet(context, ref, item),
            ),
          ],
        ),
      ),
    );
  }
```

- [ ] **Step 3: 添加 _consumeOne 方法**

在 `_showMarkConsumedDialog` 方法前（约第 502 行），添加以下方法：

```dart
  /// 快速消耗 1 个
  void _consumeOne(BuildContext context, WidgetRef ref, Item item) {
    ref.read(itemsProvider.notifier).consumeItem(item.id, quantity: 1);
    
    final newQuantity = item.quantity - 1;
    
    if (newQuantity <= 0) {
      // 已消耗完毕，返回上一页
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已使用完毕')),
      );
    } else {
      // 显示剩余数量
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('消耗成功，剩余 $newQuantity ${item.unit}')),
      );
    }
  }

  /// 显示消耗面板
  void _showConsumeBottomSheet(BuildContext context, WidgetRef ref, Item item) {
    ConsumeBottomSheet.show(
      context: context,
      item: item,
      onConfirm: (quantity) {
        ref.read(itemsProvider.notifier).consumeItem(item.id, quantity: quantity);
        
        final newQuantity = item.quantity - quantity;
        
        if (newQuantity <= 0) {
          // 已消耗完毕，返回上一页
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('已使用完毕')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('消耗成功，剩余 $newQuantity ${item.unit}')),
          );
        }
      },
    );
  }
```

- [ ] **Step 4: 修改 _buildActionButton 方法签名**

找到 `_buildActionButton` 方法（约第 429 行），修改 `onPressed` 参数类型，允许为 null：

```dart
  /// 构建操作按钮
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    bool isDestructive = false,
    VoidCallback? onPressed,  // 改为可空
  }) {
    final isEnabled = onPressed != null;
    return Container(
      width: 72,
      height: 48,
      decoration: BoxDecoration(
        color: isDestructive
            ? AppColors.errorContainer.withOpacity(0.3)
            : AppColors.surfaceContainer,
        borderRadius: AppRadius.medium,
        border: Border.all(
          color: isDestructive
              ? AppColors.error.withOpacity(0.3)
              : AppColors.outlineVariant.withOpacity(0.3),
        ),
      ),
      child: InkWell(
        onTap: onPressed,
        borderRadius: AppRadius.medium,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20,
              color: isDestructive 
                  ? (isEnabled ? AppColors.error : AppColors.onSurfaceVariant)
                  : (isEnabled ? AppColors.onSurface : AppColors.onSurfaceVariant),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: AppTypography.labelCaps.copyWith(
                fontSize: 10,
                color: isDestructive 
                    ? (isEnabled ? AppColors.error : AppColors.onSurfaceVariant)
                    : (isEnabled ? AppColors.onSurface : AppColors.onSurfaceVariant),
              ),
            ),
          ],
        ),
      ),
    );
  }
```

- [ ] **Step 5: 验证编译通过**

运行: `cd H:/code/food_app && flutter analyze lib/pages/item_detail_page.dart`

预期: No issues found

---

### Task 6: ReminderCenterPage - 改造任务卡片按钮

**Files:**
- Modify: `lib/pages/reminder_center_page.dart`

- [ ] **Step 1: 添加 import 语句**

在 `lib/pages/reminder_center_page.dart` 文件顶部，添加导入：

```dart
import '../widgets/consume_bottom_sheet.dart';
```

在现有的 import 区域（约第 11 行后）添加。

- [ ] **Step 2: 修改任务卡片中的操作按钮**

找到 `_buildTaskCard` 方法中的操作按钮部分（约第 446-464 行），替换为以下代码：

```dart
                  // 操作按钮
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 忽略按钮
                      _buildActionButton(
                        icon: Icons.close,
                        onPressed: () => _showDismissDialog(context, ref, item),
                        isPrimary: false,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      // 已使用按钮（带下拉）
                      _buildConsumeButton(context, ref, item),
                    ],
                  ),
```

- [ ] **Step 3: 添加 _buildConsumeButton 方法**

在 `_buildActionButton` 方法后（约第 538 行），添加以下方法：

```dart
  /// 构建消耗按钮（带下拉箭头）
  Widget _buildConsumeButton(BuildContext context, WidgetRef ref, Item item) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 主按钮 - 快速消耗 1 个
          GestureDetector(
            onTap: () => _consumeOne(context, ref, item),
            child: Padding(
              padding: const EdgeInsets.only(left: AppSpacing.md),
              child: Row(
                children: [
                  Icon(
                    Icons.check,
                    size: 18,
                    color: AppColors.onPrimary,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    '已使用',
                    style: AppTypography.labelCaps.copyWith(
                      color: AppColors.onPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // 下拉箭头 - 显示消耗面板
          GestureDetector(
            onTap: () => _showConsumeBottomSheet(context, ref, item),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              child: Icon(
                Icons.arrow_drop_down,
                size: 20,
                color: AppColors.onPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 快速消耗 1 个
  void _consumeOne(BuildContext context, WidgetRef ref, Item item) {
    // 立即从 UI 中移除
    ref.read(reminderProvider.notifier).removeItem(item.id);
    
    // 异步更新数据库
    ref.read(itemsProvider.notifier).consumeItem(item.id, quantity: 1);
    
    final newQuantity = item.quantity - 1;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(newQuantity <= 0 
            ? '已使用完毕' 
            : '消耗成功，剩余 $newQuantity ${item.unit}'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// 显示消耗面板
  void _showConsumeBottomSheet(BuildContext context, WidgetRef ref, Item item) {
    ConsumeBottomSheet.show(
      context: context,
      item: item,
      onConfirm: (quantity) {
        // 从提醒列表移除
        ref.read(reminderProvider.notifier).removeItem(item.id);
        
        // 更新数据库
        ref.read(itemsProvider.notifier).consumeItem(item.id, quantity: quantity);
        
        final newQuantity = item.quantity - quantity;
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(newQuantity <= 0 
                ? '已使用完毕' 
                : '消耗成功，剩余 $newQuantity ${item.unit}'),
            duration: const Duration(seconds: 2),
          ),
        );
      },
    );
  }
```

- [ ] **Step 4: 验证编译通过**

运行: `cd H:/code/food_app && flutter analyze lib/pages/reminder_center_page.dart`

预期: No issues found

---

### Task 7: 整体验证与测试

**Files:**
- 无文件修改

- [ ] **Step 1: 完整分析检查**

运行: `cd H:/code/food_app && flutter analyze`

预期: No issues found

- [ ] **Step 2: 尝试构建**

运行: `cd H:/code/food_app && flutter build apk --debug`

预期: 构建成功

---

## 自检清单

### 规格覆盖
- [x] DatabaseService 新增 updateItemQuantity 方法 - Task 1
- [x] ItemProvider 新增 consumeItem 方法 - Task 2
- [x] QuantitySelector 组件 - Task 3
- [x] ConsumeBottomSheet 组件 - Task 4
- [x] ItemDetailPage 底部栏改造 - Task 5
- [x] ReminderCenterPage 按钮改造 - Task 6
- [x] 错误处理（数量边界检查）- Task 3, Task 4

### 占位符检查
- 无 TBD、TODO 等占位符
- 所有代码步骤均包含完整实现

### 类型一致性
- `consumeItem(String id, {int quantity = 1})` - 签名在各处保持一致
- `QuantitySelector` 组件属性命名一致
- `ConsumeBottomSheet.show()` 静态方法签名一致
