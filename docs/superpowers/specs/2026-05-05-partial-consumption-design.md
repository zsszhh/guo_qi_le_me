# 物品部分消耗功能设计文档

## 概述

当前系统的"标记已使用"功能会将物品整个标记为消耗完毕，不支持部分消耗。本设计增加数量选择功能，允许用户消耗指定数量的物品。

## 目标

- 支持部分消耗物品数量
- 保持交互简洁高效
- 与现有系统无缝集成

## 数据层设计

### ItemProvider 新增方法

```dart
/// 消耗物品（支持部分消耗）
Future<void> consumeItem(String itemId, {int quantity = 1}) async {
  final item = state.items.where((i) => i.id == itemId).firstOrNull;
  if (item == null) return;

  final newQuantity = item.quantity - quantity;

  if (newQuantity <= 0) {
    // 数量归零，标记为已消耗
    await markAsConsumed(itemId);
  } else {
    // 更新剩余数量
    final updatedItem = item.copyWith(
      quantity: newQuantity,
      updatedAt: DateTime.now(),
    );
    await _dbService.updateItem(updatedItem);
    await loadItems();
  }
}
```

### 数据库

无需修改表结构，`quantity` 字段已存在。

## 新增组件

### 1. QuantitySelector - 数量选择器

**文件：** `lib/widgets/quantity_selector.dart`

**属性：**
- `currentValue` - 当前数量
- `maxValue` - 最大可选数量
- `minValue` - 最小值，默认 1
- `unit` - 单位显示
- `onChanged` - 数量变化回调

**UI 结构：**
```
[−]    [  3  ]    [+]   个
```

### 2. ConsumeBottomSheet - 消耗面板

**文件：** `lib/widgets/consume_bottom_sheet.dart`

**属性：**
- `item` - 当前物品
- `onConfirm` - 确认消耗回调

**UI 结构：**
```
┌─────────────────────────────────────┐
│  消耗数量                     [×]   │
├─────────────────────────────────────┤
│  苹果（剩余 5 个）                  │
│  [QuantitySelector 组件]            │
├─────────────────────────────────────┤
│         [ 确认消耗 ]                │
└─────────────────────────────────────┘
```

## 页面修改

### 物品详情页 (ItemDetailPage)

**底部操作栏改造：**

| 当前 | 改造后 |
|------|--------|
| `[编辑] [删除] [标记已使用]` | `[编辑] [删除] [使用1个] [更多▼]` |

**交互逻辑：**

| 操作 | 行为 |
|------|------|
| 点击「使用1个」 | 立即消耗 1 个，显示 Toast |
| 点击「更多▼」 | 弹出 ConsumeBottomSheet |

**消耗后处理：**
- 数量 > 0：更新页面显示，保留在详情页
- 数量 = 0：标记已消耗，返回上一页

### 提醒页面 (ReminderCenterPage)

**任务卡片按钮改造：**

| 当前 | 改造后 |
|------|--------|
| `[×] [已使用]` | `[×] [已使用 ▼]` |

**交互逻辑：**

| 操作 | 行为 |
|------|------|
| 点击「已使用」主体 | 快速消耗 1 个，卡片移除 |
| 点击「▼」箭头 | 弹出 ConsumeBottomSheet |

**消耗后处理：**
- 数量 > 0：卡片从提醒列表移除
- 数量 = 0：标记已消耗，卡片移除

## 错误处理

| 场景 | 处理方式 |
|------|----------|
| 消耗数量 > 库存 | 禁用确认按钮，显示"超出可用数量" |
| 消耗数量 = 0 | 禁用确认按钮 |
| 网络请求失败 | Toast 提示"操作失败，请重试" |
| 物品已被删除 | Toast 提示"物品不存在"，返回 |

## 文件清单

### 新增文件

| 文件 | 说明 |
|------|------|
| `lib/widgets/quantity_selector.dart` | 数量选择器组件 |
| `lib/widgets/consume_bottom_sheet.dart` | 消耗面板组件 |

### 修改文件

| 文件 | 修改内容 |
|------|----------|
| `lib/providers/item_provider.dart` | 新增 `consumeItem()` 方法 |
| `lib/services/database_service.dart` | 新增 `updateItemQuantity()` 方法 |
| `lib/pages/item_detail_page.dart` | 改造底部操作栏 |
| `lib/pages/reminder_center_page.dart` | 改造任务卡片按钮 |
