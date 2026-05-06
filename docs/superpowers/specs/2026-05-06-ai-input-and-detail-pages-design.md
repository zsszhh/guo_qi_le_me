# AI录入页面与物品详情页设计规格

## 概述

本文档定义了两个核心页面的UI改版设计：
1. **AI录入页面** - 导航栏中间按钮进入，参照 `stitch_ai_expiry_guardian/ai_1`
2. **物品详情页** - 点击物品后进入，参照 `stitch_ai_expiry_guardian/ai_2`

### 设计原则
- 遵循 stitch 设计系统（见 `guardian_system/DESIGN.md`）
- 中文为主，仅特定术语保留英文
- 渐进式改造现有页面，保留业务逻辑

---

## 一、AI录入页面

### 1.1 页面结构

```
┌─────────────────────────────┐
│        标题区域              │
│   "添加物品" + 副标题         │
├─────────────────────────────┤
│                             │
│      ┌─────────────┐        │
│      │             │        │
│      │   拍照按钮   │        │
│      │  (大圆形)    │        │
│      │             │        │
│      └─────────────┘        │
│                             │
├─────────────────────────────┤
│    ┌───────────────────┐    │
│    │ 🎤 语音录入        │    │
│    └───────────────────┘    │
├─────────────────────────────┤
│  最近添加                    │
│  ┌─────┐ ┌─────┐ ┌─────┐    │
│  │卡片1│ │卡片2│ │卡片3│ ←─ 横向滚动
│  └─────┘ └─────┘ └─────┘    │
├─────────────────────────────┤
│     ✏️ 手动录入 (链接)       │
└─────────────────────────────┘
```

### 1.2 布局参数

| 属性 | 值 |
|------|------|
| 页面背景 | `AppColors.background` (#f9f9ff) |
| 水平内边距 | `AppSpacing.containerMargin` (20px) |
| 内容最大宽度 | 512px，居中 |
| 顶部预留空间 | 100px（为AppBar留空） |

### 1.3 标题区域

| 元素 | 样式 |
|------|------|
| 主标题 | "添加物品"，`AppTypography.display` (32px, bold)，`onSurface` |
| 副标题 | "让AI帮你处理过期日期"，`AppTypography.bodyBase` (16px)，`onSurfaceVariant` |
| 对齐 | 居中 |
| 下边距 | `AppSpacing.xl` (32px) |

### 1.4 拍照按钮（核心组件）

| 属性 | 值 |
|------|------|
| 尺寸 | 224px × 224px |
| 形状 | 圆形 |
| 背景 | `LinearGradient`：`primaryContainer` → `primaryFixed` |
| 边框 | 6px solid `surfaceContainerLow` |
| 阴影 | `0 12px 48px rgba(74,222,128,0.6)` - 绿色光晕效果 |
| 图标 | `photo_camera`，64px，`onPrimaryContainer` |
| 主文字 | "拍照识别"，`AppTypography.titleLg` |
| 副文字 | "📸 拍照识别"，`AppTypography.bodySm`，透明度80% |

### 1.5 语音录入按钮

| 属性 | 值 |
|------|------|
| 最大宽度 | 320px |
| 高度 | 约64px |
| 形状 | 胶囊形（圆角full） |
| 背景 | `surfaceContainerHigh` |
| 边框 | 1px solid `rgba(255,255,255,0.5)` |
| 阴影 | `AppShadows.card` |
| 图标 | `mic`，`primary`色 |
| 主文字 | "语音录入"，`AppTypography.bodyBase`，加粗 |
| 副文字 | "🎤 语音录入"，`AppTypography.bodySm`，`onSurfaceVariant` |
| 对齐 | 居中 |

### 1.6 最近物品区域

**标题**
- 文字："最近添加"，`AppTypography.labelCaps` (12px)，`onSurfaceVariant`
- 下边距：`AppSpacing.sm` (12px)

**横向滚动列表**
- 滚动方向：水平
- 滚动条：隐藏
- 卡片间距：`AppSpacing.md` (16px)
- 吸附：snap to start

**最近物品卡片**

| 属性 | 值 |
|------|------|
| 宽度 | 140px |
| 内边距 | `AppSpacing.md` (16px) |
| 背景 | `surface` |
| 边框 | 1px `outlineVariant` |
| 圆角 | `AppRadius.lg` (16px) |
| 阴影 | `AppShadows.card` |

卡片内容：
- 分类图标 + 分类名（如 `egg` + "食品"）
- 物品名称（加粗）
- 保质期增量徽章（如 "+ 14 天"）

**交互**
- 点击：快速复制录入（预填充表单）

### 1.7 手动录入链接

| 属性 | 值 |
|------|------|
| 图标 | `edit_square`，18px |
| 文字 | "手动录入"，`AppTypography.bodySm`，加粗 |
| 颜色 | `onSurfaceVariant` → hover时 `onSurface` |
| 对齐 | 居中 |

---

## 二、物品详情页

### 2.1 页面结构

```
┌─────────────────────────────┐
│  ← 物品详情         ⋮       │  顶部AppBar
├─────────────────────────────┤
│                             │
│    ┌───────────────────┐    │
│    │                   │    │
│    │    物品大图        │    │  Hero区域
│    │                   │    │
│    │                   │    │
│    │ [还有 2 天过期]    │    │  ← 状态徽章(叠加)
│    └───────────────────┘    │
│                             │
│  有机全脂牛奶                │  标题
│  乳制品 • 1加仑 • 已开封      │  副标题
├─────────────────────────────┤
│  ┌─────────────────────┐    │
│  │ 📊 生命周期          │    │  时间轴进度条
│  │   ├─────●─────┤     │    │
│  │ 购买      今天    过期 │
│  └─────────────────────┘    │
├─────────────────────────────┤
│  ┌─────────────────────┐    │
│  │ ✨ AI保质期分析       │    │  AI分析卡片
│  │    分析内容...       │    │
│  └─────────────────────┘    │
├─────────────────────────────┤
│  ┌────┐ ┌────┐ ┌──────────┐│  底部操作栏
│  │编辑│ │删除│ │ 标记已用  ││
│  └────┘ └────┘ └──────────┘│
└─────────────────────────────┘
```

### 2.2 顶部AppBar

| 属性 | 值 |
|------|------|
| 背景 | `background` 透明度80% + 模糊效果 |
| 高度 | 64px |
| 标题 | "物品详情"，`AppTypography.headlineMd` |
| 左按钮 | 返回箭头，圆形点击区域 |
| 右按钮 | 更多菜单（三点），圆形点击区域 |
| 底部边框 | 1px `surfaceVariant` |

### 2.3 Hero大图区域

| 属性 | 值 |
|------|------|
| 宽度 | 100% |
| 高宽比 | 1:1（移动端），16:9（宽屏） |
| 圆角 | `AppRadius.xl` (24px) |
| 边框 | 1px `outlineVariant` 透明度30% |
| 阴影 | 轻微阴影 |
| 背景 | `surfaceVariant`（加载中/无图片时） |

**图片显示**
- 有图片：`fit: cover`，圆角裁剪
- 无图片：显示分类图标，居中，`primary`色，尺寸40px

**状态徽章（叠加）**
- 位置：左上角，距离边缘16px
- 背景：根据状态选择颜色
  - 紧急/过期：`errorContainer`
  - 即将过期：`secondaryContainer`
  - 正常：`primaryContainer`
- 内容：状态图标 + 文字
  - "已过期 X 天"
  - "还有 X 天过期"
  - "正常"
- 圆角：`AppRadius.full`
- 阴影：`BoxShadow(color: Colors.black26, blurRadius: 4)`

### 2.4 标题区域

| 元素 | 样式 |
|------|------|
| 物品名称 | `AppTypography.display` (32px, bold)，`onSurface` |
| 副标题 | "分类 • 规格 • 状态"，`AppTypography.bodyBase`，`onSurfaceVariant` |
| 上边距 | `AppSpacing.md` (16px) |
| 下边距 | `AppSpacing.xl` (32px) |

### 2.5 生命周期时间轴卡片

| 属性 | 值 |
|------|------|
| 背景 | `surface` |
| 圆角 | `AppRadius.xl` (24px) |
| 内边距 | `AppSpacing.lg` (24px) |
| 阴影 | `AppShadows.card` |

**标题**
- 图标：`timeline`，`primary`色
- 文字："生命周期"，`AppTypography.titleLg`

**进度条**
- 高度：12px
- 背景：`surfaceVariant`
- 填充：渐变色（根据进度）
  - 0-50%：`primary`（绿色）
  - 50-80%：`secondary`（橙色）
  - 80-100%：`error`（红色）
- 圆角：`AppRadius.full`

**标记点**
- 购买日期：左侧，`outlineVariant`，底部文字
- 今天：当前位置，圆点，高亮颜色
- 过期日期：右侧，`outlineVariant`，底部文字

### 2.6 AI保质期分析卡片

| 属性 | 值 |
|------|------|
| 背景 | `surfaceContainer` |
| 圆角 | `AppRadius.xl` (24px) |
| 内边距 | `AppSpacing.lg` (24px) |
| 边框 | 1px `primary` 透明度20% |
| 装饰 | 右上角绿色渐变光晕 |

**图标区域**
- 尺寸：40px × 40px
- 背景：`primaryContainer`，圆形
- 图标：`auto_awesome`，`onPrimaryContainer`

**内容**
- 标题："AI保质期分析"，`AppTypography.titleLg`
- 分析文本：`AppTypography.bodyBase`，`onSurfaceVariant`

**AI分析逻辑**
- 缓存Key：`分类 + 子分类 + 开封状态`
- 流程：
  1. 查询本地缓存
  2. 命中 → 直接显示
  3. 未命中 → 调用AI → 存储结果 → 显示

### 2.7 底部操作栏

| 属性 | 值 |
|------|------|
| 位置 | 固定底部 |
| 背景 | `surface` 透明度95% + backdrop-blur-xl |
| 顶部边框 | 1px `surfaceVariant` |
| 内边距 | `AppSpacing.md` (16px) |
| 最大宽度 | 512px，居中 |

**编辑按钮**
- 尺寸：48px × 48px
- 背景：`surface`，1px `outlineVariant` 边框
- 图标：`edit`，`onSurface`
- 圆角：`AppRadius.xl` (12px)

**删除按钮**
- 尺寸：48px × 48px
- 背景：`errorContainer` 透明度30%
- 图标：`delete`，`error`
- 圆角：`AppRadius.xl` (12px)

**主操作按钮**
- 宽度：flex-1
- 高度：48px
- 背景：`primary`
- 图标：`check_circle`，填充
- 文字："标记已用"，`AppTypography.titleLg`，`onPrimary`
- 圆角：`AppRadius.xl` (12px)

---

## 三、数据需求

### 3.1 最近物品查询

```dart
// 查询最近添加的5个物品
Future<List<Item>> getRecentItems({int limit = 5});
```

返回字段：
- 物品ID
- 物品名称
- 分类
- 子分类
- 保质期增量（过期日期 - 购买日期）

### 3.2 AI分析缓存

```dart
// 缓存结构
class AIAnalysisCache {
  final String cacheKey;      // 分类_子分类_开封状态
  final String analysisText;  // AI分析结果
  final DateTime createdAt;   // 创建时间
}
```

---

## 四、实现要点

### 4.1 改造策略
- 在现有页面基础上渐进式改造
- 保留现有业务逻辑（AI识别、语音录入、数据存储）
- 新增UI组件，逐步替换旧布局

### 4.2 需要新增的组件
- `PhotoRecognitionButton` - 大圆形拍照按钮
- `RecentItemsList` - 最近物品横向滚动列表
- `HeroImageSection` - 详情页大图区域
- `StatusBadge` - 状态徽章（已存在，需调整样式）
- `LifecycleTimeline` - 生命周期时间轴
- `AIAnalysisCard` - AI保质期分析卡片

### 4.3 需要修改的文件
- `lib/pages/ai_input_page.dart` - AI录入页面
- `lib/pages/item_detail_page.dart` - 物品详情页
- `lib/services/database_service.dart` - 新增最近物品查询
- `lib/services/ai_service.dart` - 新增保质期分析接口

---

## 五、验收标准

### 5.1 AI录入页面
- [ ] 拍照按钮居中显示，带有绿色光晕阴影
- [ ] 语音录入按钮显示正常
- [ ] 最近物品横向滚动，点击可快速复制录入
- [ ] 手动录入链接可点击
- [ ] 所有文字为中文

### 5.2 物品详情页
- [ ] Hero大图区域显示正确，状态徽章叠加在左上角
- [ ] 生命周期时间轴显示购买/今天/过期三个节点
- [ ] AI保质期分析卡片显示，带光晕装饰
- [ ] 底部操作栏固定，毛玻璃效果
- [ ] 所有文字为中文
