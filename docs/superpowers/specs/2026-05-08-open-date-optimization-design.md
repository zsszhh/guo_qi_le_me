# 开封时间功能优化设计

> 创建日期：2026-05-08

## 背景

当前开封时间功能存在以下问题：
- 记录开封时间需要进入编辑页面，操作路径过长
- 开封后缺乏智能保质建议
- 用户日常使用时难以快速标记开封状态

## 目标

1. 提供快速开封入口，缩短操作路径
2. 智能评估开封后的最佳使用/食用时间
3. 醒目展示建议日期，帮助用户及时消耗物品

## 设计方案

### 1. 数据模型

**新增字段：**

```dart
class Item {
  // 现有字段...
  final DateTime? openedDate;           // 开封日期（已有）

  // 新增字段
  final DateTime? suggestedUseDate;     // 建议使用日期
  final String? useDateSource;          // 建议日期来源：'rule' | 'ai' | 'fallback' | null
  final bool isIndividuallyWrapped;     // 是否独立包装，默认 false
}
```

**字段说明：**
- `suggestedUseDate`：系统建议的"最佳使用/食用日期"，基于开封时间计算
- `useDateSource`：标记建议来源，区分规则库、AI 分析或兜底默认值
- `isIndividuallyWrapped`：独立包装物品无需开封后保质建议

**数据库变更：**
- 新增 `suggested_use_date TEXT`
- 新增 `use_date_source TEXT`
- 新增 `is_individually_wrapped INTEGER`（SQLite 用 0/1 表示布尔）
- 数据库版本升级，需迁移脚本

### 2. 开封保质期规则库

**存储位置：** `lib/data/expiry_rules.dart`

**数据结构：**

```dart
class ExpiryRule {
  final String category;        // 主分类，如 "食品"
  final String? subCategory;    // 子分类，如 "牛奶"，null 表示该分类通用
  final int daysAfterOpened;    // 开封后建议天数
  final String? storageTip;     // 存储提示，如 "需冷藏"
}
```

**预设规则示例：**

| 分类 | 子分类 | 开封后天数 | 存储提示 |
|------|--------|-----------|----------|
| 食品 | 牛奶 | 3 | 需冷藏 |
| 食品 | 酸奶 | 3 | 需冷藏 |
| 食品 | 鸡蛋 | 14 | 常温或冷藏 |
| 食品 | 酱油 | 90 | 阴凉处 |
| 食品 | 蛋黄酱 | 60 | 需冷藏 |
| 食品 | 面包 | 3 | 密封保存 |
| 食品 | (默认) | 7 | - |
| 药品 | 眼药水 | 28 | 避光保存 |
| 药品 | 糖浆 | 30 | 密封阴凉 |
| 药品 | (默认) | 30 | - |
| 化妆品 | (默认) | 90 | - |

**匹配逻辑：**
1. 精确匹配：主分类 + 子分类
2. 分类默认：仅主分类
3. 全局默认：7 天

### 3. 快速开封按钮

**位置：** 物品卡片（`ItemCard` 组件）

**展示条件：**
- `openedDate == null`（未开封）
- `isIndividuallyWrapped == false`（非独立包装）

**UI 设计：**
- 小型圆角按钮，显示"开封"或图标+文字
- 颜色：主题色或柔和蓝色
- 位于卡片右下角或底部

**交互流程：**
1. 用户点击"开封"按钮
2. 按钮变为加载状态
3. 查规则库 → 有则直接计算 `suggestedUseDate`
4. 无规则 → 调用 AI 分析，返回建议日期
5. 更新物品数据（`openedDate`、`suggestedUseDate`、`useDateSource`）
6. 按钮消失，卡片刷新显示建议日期

### 4. AI 深度分析

**触发条件：** 规则库中没有匹配的物品

**输入参数：**
- 物品名称、分类、子分类
- 品牌、规格（如有）
- 存放位置

**输出格式：**

```json
{
  "suggestedDays": 7,
  "reasoning": "简短说明原因",
  "storageTip": "存储建议"
}
```

**结果处理：**
- 计算 `suggestedUseDate = openedDate + suggestedDays`
- 存储 `useDateSource = 'ai'`
- 可选展示 AI 的推理说明

### 5. 建议日期展示

**物品卡片展示：**

对于已开封物品，在卡片底部显示建议日期：

```
⚠️ 建议在 5月15日 前用完
```

**样式逻辑：**
- 距建议日期 > 3 天：灰色/蓝色文字
- 距建议日期 1-3 天：橙色文字 + ⚠️ 图标
- 已超过建议日期：红色文字 + ❗ 图标

**物品详情页展示：**

在生命周期时间轴中增加"建议用完"节点：

```
购买         开封         建议用完        过期
 ●───────────●─────────────●──────────────●
 3月1日      5月8日       5月15日        6月1日
```

或在详情信息区域显示醒目的提示卡片。

### 6. 独立包装处理

**子分类预设：**

在现有子分类数据中标记默认独立包装类型：

```dart
const subCategories = {
  '食品': [
    {'name': '牛奶', 'defaultIndividuallyWrapped': false},
    {'name': '独立包装牛奶', 'defaultIndividuallyWrapped': true},
    {'name': '独立小包零食', 'defaultIndividuallyWrapped': true},
    // ...
  ],
};
```

**逻辑：**
- 新建物品时，根据子分类自动设置 `isIndividuallyWrapped`
- 用户可在编辑页手动修改
- 独立包装物品不显示快速开封按钮，不生成建议日期

### 7. 边界情况

| 场景 | 处理方式 |
|------|----------|
| AI 调用失败 | 使用全局默认 7 天，`useDateSource = 'fallback'` |
| 用户未配置 AI | 仅使用规则库，无匹配时用默认 7 天 |
| 物品已过期 | 建议日期不应晚于过期日期，取两者较早者 |
| 独立包装物品 | 不显示开封按钮，不生成建议日期 |

## 涉及文件

| 文件 | 变更内容 |
|------|----------|
| `lib/models/item.dart` | 新增 3 个字段 |
| `lib/services/database_service.dart` | 数据库迁移，新增字段 |
| `lib/data/expiry_rules.dart` | 新建，预设规则库 |
| `lib/widgets/item_card.dart` | 添加快速开封按钮和建议日期展示 |
| `lib/pages/item_detail_page.dart` | 添加建议日期展示 |
| `lib/pages/item_edit_page.dart` | 添加独立包装选项 |
| `lib/services/ai_service.dart` | 新增开封保质期分析接口 |
| `lib/providers/item_provider.dart` | 新增快速开封方法 |

## 后续扩展

- 建议日期到期提醒通知
- 用户自定义规则库
- 开封历史记录统计
