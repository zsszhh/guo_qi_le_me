---
name: 产品图库与历史数据复用
description: 添加产品图片推荐和历史数据复用功能，优化重复添加物品的体验
type: project
---

# 产品图库与历史数据复用设计

## 背景

用户在添加物品时，经常需要重复输入相似的物品（如不同批次的牛奶）。目前缺少：
1. 产品图片复用机制
2. 历史数据快速填充

## 目标

1. **产品图库** - 点击添加图片时，根据物品名称模糊匹配推荐已有产品图
2. **历史数据复用** - 输入名称后自动检测相似物品，弹窗询问是否复用
3. **完整同步** - WebDAV 同步时包含数据库和图片文件

## 架构设计

```
┌─────────────────────────────────────────────────────────┐
│                    ItemEditPage                          │
│  ┌─────────────────┐    ┌─────────────────────────────┐ │
│  │ 名称输入框       │    │ 图片选择区域                 │ │
│  │   ↓ 失焦触发     │    │   ↓ 点击触发                │ │
│  │ 历史数据推荐弹窗  │    │ 产品图推荐 + 拍照/相册      │ │
│  └─────────────────┘    └─────────────────────────────┘ │
└─────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────┐
│                   ProductService                         │
│  - searchProductImages(name) 模糊搜索产品图              │
│  - searchSimilarItems(name) 搜索相似物品                 │
│  - saveProductImage(name, imagePath) 保存产品图          │
└─────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────┐
│                   数据层                                  │
│  ┌───────────────┐    ┌───────────────────────────────┐ │
│  │ items 表       │    │ product_images 表             │ │
│  │ (物品数据)     │    │ (产品图: name + image_path)   │ │
│  └───────────────┘    └───────────────────────────────┘ │
│                          │                               │
│                          ▼                               │
│               ┌─────────────────────┐                    │
│               │ item_images/ 目录    │                    │
│               │ (图片文件存储)        │                    │
│               └─────────────────────┘                    │
└─────────────────────────────────────────────────────────┘
```

## 数据模型

### product_images 表

| 字段 | 类型 | 说明 |
|------|------|------|
| id | TEXT | 主键，UUID |
| name | TEXT | 产品名称，用于模糊匹配 |
| image_path | TEXT | 图片本地存储路径 |
| created_at | TEXT | 创建时间 |

### ProductImage 实体类

```dart
class ProductImage {
  final String id;
  final String name;
  final String imagePath;
  final DateTime createdAt;
}
```

## 交互流程

### 历史数据复用

```
用户输入物品名称 → 点击其他地方（失焦）
         ↓
   查询相似物品（name LIKE '%名称%'）
         ↓
    ┌────────────────────┐
    │ 有匹配？            │
    └────────────────────┘
      ↓ 是              ↓ 否
弹出选择弹窗        无操作，继续填写
      ↓
用户选择某个历史物品
      ↓
自动填充表单（分类、品牌、规格、单位、位置、图片）
日期和数量不填充
      ↓
用户可修改任何字段
      ↓
保存
```

### 产品图推荐

```
用户点击图片区域
         ↓
   查询匹配的产品图（name LIKE '%当前名称%'）
         ↓
弹出底部菜单：
┌─────────────────────────────┐
│ 📷 推荐图片                  │
│ ├─ 牛奶 (之前添加的产品图)    │
│ └─ 纯牛奶 (之前添加的产品图)  │
├─────────────────────────────┤
│ 📷 拍照                     │
│ 🖼️ 从相册选择               │
│ ❌ 移除图片 (已有图片时显示)  │
└─────────────────────────────┘
```

## 服务层设计

### ProductImageService（新建）

```dart
class ProductImageService {
  /// 保存产品图（上传图片时调用）
  Future<void> saveProductImage(String name, String imagePath);

  /// 搜索匹配的产品图（点击图片区域时调用）
  Future<List<ProductImage>> searchProductImages(String keyword);

  /// 删除产品图（可选，用于管理）
  Future<void> deleteProductImage(String id);

  /// 获取所有产品图（用于展示/管理）
  Future<List<ProductImage>> getAllProductImages();
}
```

### ItemProvider 扩展

```dart
/// 搜索相似物品（历史数据复用）
Future<List<Item>> searchSimilarItems(String name);
```

### 保存物品时的逻辑

```
保存物品
    ↓
有图片？
    ↓ 是
同时保存到 product_images 表
（如果该产品名已有图片，跳过）
    ↓
完成
```

## 同步设计

### 备份流程

```
1. 导出数据库文件 (.db)
2. 打包 item_images/ 目录为 images.zip
3. 上传到 WebDAV：
   /过期了么/backup_20260504.db
   /过期了么/backup_20260504_images.zip
```

### 恢复流程

```
1. 从 WebDAV 下载 .db 和 .zip
2. 关闭数据库连接
3. 覆盖数据库文件
4. 解压 images.zip 到 item_images/
5. 重新打开数据库
```

### 代码清理

删除 JSON 导出相关代码：
- `BackupService.exportToJsonFile()`
- `BackupService.importFromJsonFile()`
- `DatabaseService.exportAllData()`
- `DatabaseService.importAllData()`

## 文件修改清单

| 文件 | 修改内容 |
|------|----------|
| `lib/models/product_image.dart` | 新建，产品图实体类 |
| `lib/services/database_service.dart` | 新增 product_images 表，新增查询方法 |
| `lib/services/product_image_service.dart` | 新建，产品图服务 |
| `lib/services/webdav_service.dart` | 扩展图片打包上传/下载恢复 |
| `lib/services/backup_service.dart` | 删除 JSON 导出相关代码 |
| `lib/pages/item_edit_page.dart` | 新增历史数据复用弹窗、产品图推荐 |
| `lib/providers/item_provider.dart` | 新增搜索相似物品方法 |

## 核心功能点

1. **产品图表独立** - 与物品表解耦，删除物品不删除产品图
2. **模糊匹配** - 使用 SQL LIKE 实现名称模糊搜索
3. **图片复用** - 选择推荐图片时复制文件，不共用路径
4. **同步完整** - 数据库 + 图片目录一起打包传输
