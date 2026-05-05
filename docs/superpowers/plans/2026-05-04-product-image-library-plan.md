# 产品图库与历史数据复用实现计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 实现产品图片推荐和历史数据复用功能，优化重复添加物品的体验，并扩展WebDAV同步支持图片。

**Architecture:** 新增 product_images 表独立存储产品图信息，与物品表解耦。ItemEditPage 新增历史数据复用弹窗和产品图推荐交互。WebDAV同步扩展为打包数据库+图片目录。

**Tech Stack:** Flutter, Riverpod, SQLite (sqflite), image_picker, archive (新增用于zip压缩), WebDAV

---

## 文件结构

| 文件 | 职责 |
|------|------|
| `lib/models/product_image.dart` | 产品图实体类 |
| `lib/services/database_service.dart` | 数据库服务，新增 product_images 表 |
| `lib/services/product_image_service.dart` | 产品图服务，处理产品图的增删查 |
| `lib/providers/item_provider.dart` | 新增搜索相似物品方法 |
| `lib/pages/item_edit_page.dart` | 新增历史数据复用弹窗、产品图推荐 |
| `lib/services/webdav_service.dart` | 扩展图片打包上传/下载恢复 |
| `lib/services/backup_service.dart` | 删除 JSON 导出相关代码 |
| `pubspec.yaml` | 新增 archive 依赖 |

---

## Task 1: 添加 archive 依赖

**Files:**
- Modify: `pubspec.yaml`

- [ ] **Step 1: 添加 archive 依赖到 pubspec.yaml**

在 `pubspec.yaml` 的 dependencies 部分添加 archive 包：

```yaml
# 压缩解压
archive: ^4.0.4
```

位置在 `path_provider: ^2.1.5` 之后。

- [ ] **Step 2: 安装依赖**

Run: `flutter pub get`
Expected: 依赖安装成功，无冲突

- [ ] **Step 3: 提交**

```bash
git add pubspec.yaml pubspec.lock
git commit -m "chore: add archive dependency for image zip compression"
```

---

## Task 2: 创建 ProductImage 模型

**Files:**
- Create: `lib/models/product_image.dart`

- [ ] **Step 1: 创建 ProductImage 模型类**

```dart
import 'package:uuid/uuid.dart';

/// 产品图片实体
/// 用于存储产品名称与图片的映射关系，支持图片复用
class ProductImage {
  final String id;
  final String name;
  final String imagePath;
  final DateTime createdAt;

  const ProductImage({
    required this.id,
    required this.name,
    required this.imagePath,
    required this.createdAt,
  });

  /// 从 JSON 创建
  factory ProductImage.fromJson(Map<String, dynamic> json) {
    return ProductImage(
      id: json['id'] as String,
      name: json['name'] as String,
      imagePath: json['image_path'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'image_path': imagePath,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// 复制并修改
  ProductImage copyWith({
    String? id,
    String? name,
    String? imagePath,
    DateTime? createdAt,
  }) {
    return ProductImage(
      id: id ?? this.id,
      name: name ?? this.name,
      imagePath: imagePath ?? this.imagePath,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
```

- [ ] **Step 2: 提交**

```bash
git add lib/models/product_image.dart
git commit -m "feat: add ProductImage model for product image library"
```

---

## Task 3: 扩展 DatabaseService 支持产品图表

**Files:**
- Modify: `lib/services/database_service.dart`

- [ ] **Step 1: 添加 product_images 表常量**

在 `DatabaseService` 类中，添加表名常量（约第36行后）：

```dart
static const String tableProductImages = 'product_images';
```

- [ ] **Step 2: 更新数据库版本号**

将 `_databaseVersion` 从 2 改为 3：

```dart
static const int _databaseVersion = 3;
```

- [ ] **Step 3: 在 _onCreate 方法中添加 product_images 表创建语句**

在 `_onCreate` 方法中，备份历史表创建之后，索引创建之前添加：

```dart
// 产品图片表
await db.execute('''
  CREATE TABLE $tableProductImages (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    image_path TEXT NOT NULL,
    created_at TEXT NOT NULL
  )
''');
```

- [ ] **Step 4: 在 _onUpgrade 方法中添加升级逻辑**

在 `_onUpgrade` 方法中，版本2升级逻辑之后添加：

```dart
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
  
  // 创建索引
  await db.execute('CREATE INDEX IF NOT EXISTS idx_product_images_name ON $tableProductImages (name)');
}
```

- [ ] **Step 5: 在 _onCreate 方法中添加索引**

在索引创建部分添加：

```dart
await db.execute('CREATE INDEX idx_product_images_name ON $tableProductImages (name)');
```

- [ ] **Step 6: 添加 ProductImage 相关操作方法**

在 `DatabaseService` 类末尾，`close()` 方法之前添加：

```dart
// ==================== 产品图片操作 ====================

/// 插入产品图片
Future<void> insertProductImage(ProductImage productImage) async {
  final db = await database;
  await db.insert(
    tableProductImages,
    productImage.toJson(),
    conflictAlgorithm: ConflictAlgorithm.replace,
  );
}

/// 根据名称搜索产品图片（模糊匹配）
Future<List<ProductImage>> searchProductImages(String keyword) async {
  final db = await database;
  final List<Map<String, dynamic>> maps = await db.query(
    tableProductImages,
    where: 'name LIKE ?',
    whereArgs: ['%$keyword%'],
    orderBy: 'created_at DESC',
    limit: 10,
  );
  return maps.map((map) => ProductImage.fromJson(map)).toList();
}

/// 检查产品名是否已有图片
Future<bool> hasProductImage(String name) async {
  final db = await database;
  final result = await db.query(
    tableProductImages,
    where: 'name = ?',
    whereArgs: [name],
    limit: 1,
  );
  return result.isNotEmpty;
}

/// 获取所有产品图片
Future<List<ProductImage>> getAllProductImages() async {
  final db = await database;
  final List<Map<String, dynamic>> maps = await db.query(
    tableProductImages,
    orderBy: 'name ASC',
  );
  return maps.map((map) => ProductImage.fromJson(map)).toList();
}

/// 删除产品图片
Future<void> deleteProductImage(String id) async {
  final db = await database;
  await db.delete(
    tableProductImages,
    where: 'id = ?',
    whereArgs: [id],
  );
}

// ==================== 相似物品搜索 ====================

/// 搜索相似物品（用于历史数据复用）
Future<List<Item>> searchSimilarItems(String name) async {
  final db = await database;
  final List<Map<String, dynamic>> maps = await db.query(
    tableItems,
    where: 'name LIKE ?',
    whereArgs: ['%$name%'],
    orderBy: 'updated_at DESC',
    limit: 10,
  );
  return maps.map((map) => Item.fromJson(map)).toList();
}
```

- [ ] **Step 7: 添加 ProductImage 模型导入**

在文件顶部添加导入：

```dart
import '../models/product_image.dart';
```

- [ ] **Step 8: 提交**

```bash
git add lib/services/database_service.dart
git commit -m "feat: add product_images table and related database operations"
```

---

## Task 4: 创建 ProductImageService

**Files:**
- Create: `lib/services/product_image_service.dart`

- [ ] **Step 1: 创建 ProductImageService 服务类**

```dart
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';
import '../models/product_image.dart';
import 'database_service.dart';

/// 产品图片服务
/// 管理产品图片的存储、查询和复用
class ProductImageService {
  static final ProductImageService _instance = ProductImageService._internal();
  factory ProductImageService() => _instance;
  ProductImageService._internal();

  final DatabaseService _dbService = DatabaseService();

  /// 保存产品图片
  /// [name] 产品名称
  /// [imagePath] 图片本地路径
  Future<ProductImage> saveProductImage(String name, String imagePath) async {
    // 检查是否已存在同名产品图
    final exists = await _dbService.hasProductImage(name);
    if (exists) {
      // 返回已存在的记录
      final existing = await _dbService.searchProductImages(name);
      final exact = existing.where((p) => p.name == name).firstOrNull;
      if (exact != null) {
        return exact;
      }
    }

    final productImage = ProductImage(
      id: const Uuid().v4(),
      name: name,
      imagePath: imagePath,
      createdAt: DateTime.now(),
    );

    await _dbService.insertProductImage(productImage);
    return productImage;
  }

  /// 搜索匹配的产品图片
  /// [keyword] 搜索关键词（物品名称）
  Future<List<ProductImage>> searchProductImages(String keyword) async {
    if (keyword.isEmpty) {
      return [];
    }
    return await _dbService.searchProductImages(keyword);
  }

  /// 获取所有产品图片
  Future<List<ProductImage>> getAllProductImages() async {
    return await _dbService.getAllProductImages();
  }

  /// 删除产品图片
  Future<void> deleteProductImage(String id, {bool deleteFile = false}) async {
    if (deleteFile) {
      // 获取图片信息
      final images = await _dbService.getAllProductImages();
      final image = images.where((p) => p.id == id).firstOrNull;
      if (image != null) {
        final file = File(image.imagePath);
        if (await file.exists()) {
          await file.delete();
        }
      }
    }
    await _dbService.deleteProductImage(id);
  }

  /// 复制产品图片给新物品使用
  /// 返回新的图片路径
  Future<String?> copyProductImageForItem(String sourceImagePath) async {
    try {
      final sourceFile = File(sourceImagePath);
      if (!await sourceFile.exists()) {
        return null;
      }

      // 获取应用目录
      final appDir = await getApplicationDocumentsDirectory();
      final imagesDir = Directory('${appDir.path}/item_images');
      if (!await imagesDir.exists()) {
        await imagesDir.create(recursive: true);
      }

      // 生成新文件名
      final fileName = '${const Uuid().v4()}${p.extension(sourceImagePath)}';
      final newPath = '${imagesDir.path}/$fileName';

      // 复制文件
      await sourceFile.copy(newPath);
      return newPath;
    } catch (e) {
      return null;
    }
  }
}
```

- [ ] **Step 2: 提交**

```bash
git add lib/services/product_image_service.dart
git commit -m "feat: add ProductImageService for product image management"
```

---

## Task 5: 扩展 ItemProvider 添加相似物品搜索

**Files:**
- Modify: `lib/providers/item_provider.dart`

- [ ] **Step 1: 在 ItemsNotifier 类中添加搜索相似物品方法**

在 `ItemsNotifier` 类中，`_updateItemStatuses` 方法之后添加：

```dart
/// 搜索相似物品（用于历史数据复用）
Future<List<Item>> searchSimilarItems(String name) async {
  if (name.isEmpty) {
    return [];
  }
  return await _dbService.searchSimilarItems(name);
}
```

- [ ] **Step 2: 提交**

```bash
git add lib/providers/item_provider.dart
git commit -m "feat: add searchSimilarItems method to ItemsNotifier"
```

---

## Task 6: 修改 ItemEditPage 添加历史数据复用弹窗

**Files:**
- Modify: `lib/pages/item_edit_page.dart`

- [ ] **Step 1: 添加必要的导入**

在文件顶部，现有导入之后添加：

```dart
import '../services/product_image_service.dart';
```

- [ ] **Step 2: 添加状态变量**

在 `_ItemEditPageState` 类中，现有状态变量之后添加：

```dart
final ProductImageService _productImageService = ProductImageService();
bool _showSimilarItemsHint = false;
List<Item> _similarItems = [];
```

- [ ] **Step 3: 为名称输入框添加失焦监听**

找到 `TextFormField` 控制器为 `_nameController` 的部分，修改为：

```dart
TextFormField(
  controller: _nameController,
  decoration: const InputDecoration(
    labelText: '物品名称 *',
    hintText: '例如：牛奶、感冒药',
  ),
  textInputAction: TextInputAction.next,
  validator: (value) {
    if (value == null || value.isEmpty) {
      return '请输入物品名称';
    }
    return null;
  },
  onChanged: (value) {
    // 名称变化时隐藏提示
    if (_showSimilarItemsHint) {
      setState(() {
        _showSimilarItemsHint = false;
      });
    }
  },
  onFieldSubmitted: (_) {
    _checkSimilarItems();
  },
),
```

- [ ] **Step 4: 添加检查相似物品的方法**

在 `_ItemEditPageState` 类中添加方法：

```dart
/// 检查相似物品
Future<void> _checkSimilarItems() async {
  final name = _nameController.text.trim();
  if (name.isEmpty) return;

  final similarItems = await ref.read(itemsProvider.notifier).searchSimilarItems(name);
  
  if (similarItems.isNotEmpty && mounted) {
    setState(() {
      _similarItems = similarItems;
      _showSimilarItemsHint = true;
    });
  }
}

/// 显示相似物品选择弹窗
Future<void> _showSimilarItemsDialog() async {
  final selected = await showModalBottomSheet<Item>(
    context: context,
    isScrollControlled: true,
    builder: (context) => DraggableScrollableSheet(
      initialChildSize: 0.5,
      maxChildSize: 0.8,
      minChildSize: 0.3,
      expand: false,
      builder: (context, scrollController) => Column(
        children: [
          // 标题
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                Text(
                  '发现相似物品',
                  style: AppTypography.titleLg.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('取消'),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // 列表
          Expanded(
            child: ListView.builder(
              controller: scrollController,
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              itemCount: _similarItems.length,
              itemBuilder: (context, index) {
                final item = _similarItems[index];
                return ListTile(
                  leading: item.imageUrl != null
                      ? ClipRRect(
                          borderRadius: AppRadius.small,
                          child: Image.file(
                            File(item.imageUrl!),
                            width: 48,
                            height: 48,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: 48,
                              height: 48,
                              color: AppColors.surfaceContainer,
                              child: const Icon(Icons.image_not_supported),
                            ),
                          ),
                        )
                      : Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainer,
                            borderRadius: AppRadius.small,
                          ),
                          child: const Icon(Icons.inventory_2_outlined),
                        ),
                  title: Text(item.name),
                  subtitle: Text(
                    '${item.category}${item.brand != null ? ' · ${item.brand}' : ''}${item.specification != null ? ' · ${item.specification}' : ''}',
                    style: AppTypography.bodySm.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  onTap: () => Navigator.pop(context, item),
                );
              },
            ),
          ),
          // 提示
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Text(
              '选择后将自动填充分类、品牌、规格等信息',
              style: AppTypography.bodySm.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    ),
  );

  if (selected != null && mounted) {
    _fillFromItem(selected);
  }
}

/// 从已有物品填充表单
void _fillFromItem(Item item) {
  setState(() {
    _category = item.category;
    _subCategory = item.subCategory;
    _brandController.text = item.brand ?? '';
    _specificationController.text = item.specification ?? '';
    _unit = item.unit;
    _location = item.location;
    _notesController.text = item.notes ?? '';
    if (item.imageUrl != null) {
      _imageUrl = item.imageUrl;
      _selectedImage = File(item.imageUrl!);
    }
    _showSimilarItemsHint = false;
  });
}
```

- [ ] **Step 5: 在名称输入框后添加提示条**

在名称输入的 `TextFormField` 后，`const SizedBox(height: AppSpacing.md),` 之后添加：

```dart
// 相似物品提示
if (_showSimilarItemsHint && _similarItems.isNotEmpty)
  Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.md),
    child: InkWell(
      onTap: _showSimilarItemsDialog,
      borderRadius: AppRadius.small,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.primaryContainer,
          borderRadius: AppRadius.small,
        ),
        child: Row(
          children: [
            Icon(Icons.lightbulb_outline, size: 20, color: AppColors.primary),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                '发现 ${_similarItems.length} 个相似物品，点击复用数据',
                style: AppTypography.bodySm.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ),
            Icon(Icons.chevron_right, size: 20, color: AppColors.primary),
          ],
        ),
      ),
    ),
  ),
```

- [ ] **Step 6: 提交**

```bash
git add lib/pages/item_edit_page.dart
git commit -m "feat: add similar items hint and data reuse dialog in ItemEditPage"
```

---

## Task 7: 修改图片选择逻辑支持产品图推荐

**Files:**
- Modify: `lib/pages/item_edit_page.dart`

- [ ] **Step 1: 重写 _pickImage 方法以支持产品图推荐**

找到 `_pickImage` 方法，替换为：

```dart
void _pickImage() async {
  final name = _nameController.text.trim();
  final recommendedImages = await _productImageService.searchProductImages(name);

  // 选择图片来源
  final source = await showModalBottomSheet<_ImageSource>(
    context: context,
    isScrollControlled: true,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 推荐图片区域
          if (recommendedImages.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  Icon(Icons.auto_awesome, size: 20, color: AppColors.primary),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    '推荐图片',
                    style: AppTypography.titleSm.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                itemCount: recommendedImages.length,
                itemBuilder: (context, index) {
                  final productImage = recommendedImages[index];
                  return GestureDetector(
                    onTap: () {
                      Navigator.pop(context, _ImageSource.recommended(productImage.imagePath));
                    },
                    child: Container(
                      width: 80,
                      margin: const EdgeInsets.only(right: AppSpacing.sm),
                      child: Column(
                        children: [
                          ClipRRect(
                            borderRadius: AppRadius.small,
                            child: Image.file(
                              File(productImage.imagePath),
                              width: 80,
                              height: 60,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                width: 80,
                                height: 60,
                                color: AppColors.surfaceContainer,
                                child: const Icon(Icons.broken_image),
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            productImage.name,
                            style: AppTypography.bodyXs.copyWith(
                              color: AppColors.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const Divider(),
          ],
          // 标准选项
          ListTile(
            leading: const Icon(Icons.camera_alt),
            title: const Text('拍照'),
            onTap: () => Navigator.pop(context, _ImageSource.camera()),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library),
            title: const Text('从相册选择'),
            onTap: () => Navigator.pop(context, _ImageSource.gallery()),
          ),
          if (_selectedImage != null || _imageUrl != null)
            ListTile(
              leading: const Icon(Icons.delete, color: AppColors.error),
              title: const Text('移除图片', style: TextStyle(color: AppColors.error)),
              onTap: () {
                Navigator.pop(context);
                setState(() {
                  _selectedImage = null;
                  _imageUrl = null;
                });
              },
            ),
        ],
      ),
    ),
  );

  if (source == null) return;

  if (source.isRecommended) {
    // 复制推荐图片
    final newPath = await _productImageService.copyProductImageForItem(source.path);
    if (newPath != null && mounted) {
      setState(() {
        _selectedImage = File(newPath);
        _imageUrl = newPath;
      });
    }
    return;
  }

  try {
    final XFile? image = await _imagePicker.pickImage(
      source: source.isCamera ? ImageSource.camera : ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 80,
    );

    if (image != null) {
      // 保存图片到应用目录
      final appDir = await getApplicationDocumentsDirectory();
      final imagesDir = Directory('${appDir.path}/item_images');
      if (!await imagesDir.exists()) {
        await imagesDir.create(recursive: true);
      }

      final fileName = '${const Uuid().v4()}${p.extension(image.path)}';
      final savedPath = '${imagesDir.path}/$fileName';
      await File(image.path).copy(savedPath);

      setState(() {
        _selectedImage = File(savedPath);
        _imageUrl = savedPath;
      });
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('选择图片失败: $e')),
      );
    }
  }
}
```

- [ ] **Step 2: 添加 _ImageSource 辅助类**

在文件末尾，`_ItemEditPageState` 类之外添加：

```dart
/// 图片来源类型（支持推荐图片）
class _ImageSource {
  final bool isCamera;
  final bool isGallery;
  final bool isRecommended;
  final String path;

  const _ImageSource._({
    this.isCamera = false,
    this.isGallery = false,
    this.isRecommended = false,
    this.path = '',
  });

  factory _ImageSource.camera() => const _ImageSource._(isCamera: true);
  factory _ImageSource.gallery() => const _ImageSource._(isGallery: true);
  factory _ImageSource.recommended(String path) => 
      _ImageSource._(isRecommended: true, path: path);
}
```

- [ ] **Step 3: 提交**

```bash
git add lib/pages/item_edit_page.dart
git commit -m "feat: add product image recommendation in image picker"
```

---

## Task 8: 保存物品时同步保存产品图

**Files:**
- Modify: `lib/pages/item_edit_page.dart`

- [ ] **Step 1: 修改 _saveItem 方法**

找到 `_saveItem` 方法，在保存物品成功后、导航返回之前添加产品图保存逻辑：

在 `await ref.read(itemsProvider.notifier).addItem(item);` 之后添加：

```dart
// 保存产品图片到产品图库
if (_imageUrl != null && _nameController.text.trim().isNotEmpty) {
  await _productImageService.saveProductImage(
    _nameController.text.trim(),
    _imageUrl!,
  );
}
```

同样在更新物品的逻辑中添加（`await ref.read(itemsProvider.notifier).updateItem(item);` 之后）：

```dart
// 更新产品图片库
if (_imageUrl != null && _nameController.text.trim().isNotEmpty) {
  await _productImageService.saveProductImage(
    _nameController.text.trim(),
    _imageUrl!,
  );
}
```

- [ ] **Step 2: 提交**

```bash
git add lib/pages/item_edit_page.dart
git commit -m "feat: save product image to library when saving item"
```

---

## Task 9: 扩展 WebDAV 同步支持图片

**Files:**
- Modify: `lib/services/webdav_service.dart`

- [ ] **Step 1: 添加 archive 导入**

在文件顶部添加：

```dart
import 'package:archive/archive.dart';
import 'package:archive/archive_io.dart';
```

- [ ] **Step 2: 添加备份图片的方法**

在 `WebDAVService` 类中添加：

```dart
/// 上传备份（包含数据库和图片）
Future<BackupHistory> uploadBackupWithImages(WebDAVConfig config) async {
  final now = DateTime.now();
  final backupId = DateTime.now().millisecondsSinceEpoch.toString();

  try {
    _initClient(config);

    // 确保远程目录存在
    await _ensureRemoteDirectory(config.remotePath);

    // 1. 上传数据库文件
    final dbPath = await getDatabasesPath();
    final dbFile = File(p.join(dbPath, DatabaseService.databaseName));

    if (!await dbFile.exists()) {
      throw Exception('数据库文件不存在');
    }

    final dbFileName = 'backup_${_formatDateForFileName(now)}.db';
    final dbRemotePath = '${config.remotePath}/$dbFileName';

    await _client!.writeFromFile(
      dbFile.path,
      dbRemotePath,
      onProgress: (count, total) {},
    );

    // 2. 打包并上传图片目录
    final appDir = await getApplicationDocumentsDirectory();
    final imagesDir = Directory('${appDir.path}/item_images');
    
    String? imagesRemotePath;
    int totalSize = await dbFile.length();

    if (await imagesDir.exists()) {
      final zipFileName = 'backup_${_formatDateForFileName(now)}_images.zip';
      final zipLocalPath = '${appDir.path}/$zipFileName';
      
      // 创建 ZIP 文件
      await _zipDirectory(imagesDir.path, zipLocalPath);
      
      final zipFile = File(zipLocalPath);
      if (await zipFile.exists()) {
        imagesRemotePath = '${config.remotePath}/$zipFileName';
        
        await _client!.writeFromFile(
          zipLocalPath,
          imagesRemotePath,
          onProgress: (count, total) {},
        );
        
        totalSize += await zipFile.length();
        
        // 删除临时 ZIP 文件
        await zipFile.delete();
      }
    }

    // 记录备份历史
    final history = BackupHistory(
      id: backupId,
      backupType: BackupType.webdav,
      status: BackupStatus.success,
      filePath: dbRemotePath,
      fileSizeBytes: totalSize,
      backupAt: now,
      createdAt: now,
    );

    await _dbService.insertBackupHistory(history);
    return history;
  } catch (e) {
    final history = BackupHistory(
      id: backupId,
      backupType: BackupType.webdav,
      status: BackupStatus.failed,
      errorMessage: e.toString(),
      backupAt: now,
      createdAt: now,
    );

    await _dbService.insertBackupHistory(history);
    rethrow;
  }
}

/// 从 WebDAV 恢复（包含数据库和图片）
Future<void> downloadAndRestoreWithImages(
  WebDAVConfig config, 
  String dbRemotePath,
  String? imagesRemotePath,
) async {
  try {
    _initClient(config);

    // 1. 下载并恢复数据库
    await _dbService.close();

    final dbPath = await getDatabasesPath();
    final localDbPath = p.join(dbPath, DatabaseService.databaseName);

    await _client!.read2File(
      dbRemotePath,
      localDbPath,
      onProgress: (count, total) {},
    );

    // 2. 下载并解压图片（如果有）
    if (imagesRemotePath != null) {
      final appDir = await getApplicationDocumentsDirectory();
      final zipLocalPath = '${appDir.path}/restore_images.zip';
      
      await _client!.read2File(
        imagesRemotePath,
        zipLocalPath,
        onProgress: (count, total) {},
      );

      // 解压到 item_images 目录
      final imagesDir = Directory('${appDir.path}/item_images');
      if (await imagesDir.exists()) {
        await imagesDir.delete(recursive: true);
      }
      await imagesDir.create(recursive: true);
      
      await _unzipFile(zipLocalPath, imagesDir.path);
      
      // 删除临时 ZIP 文件
      final zipFile = File(zipLocalPath);
      if (await zipFile.exists()) {
        await zipFile.delete();
      }
    }
  } catch (e) {
    rethrow;
  }
}

/// 打包目录为 ZIP 文件
Future<void> _zipDirectory(String sourcePath, String targetPath) async {
  final archive = Archive();
  final sourceDir = Directory(sourcePath);

  if (!await sourceDir.exists()) return;

  await for (final entity in sourceDir.list(recursive: true)) {
    if (entity is File) {
      final relativePath = p.relative(entity.path, from: sourcePath);
      final bytes = await entity.readAsBytes();
      
      archive.addFile(ArchiveFile(
        relativePath,
        bytes.length,
        bytes,
      ));
    }
  }

  final zipBytes = ZipEncoder().encode(archive);
  if (zipBytes != null) {
    await File(targetPath).writeAsBytes(zipBytes);
  }
}

/// 解压 ZIP 文件到目录
Future<void> _unzipFile(String zipPath, String targetPath) async {
  final bytes = await File(zipPath).readAsBytes();
  final archive = ZipDecoder().decodeBytes(bytes);

  for (final file in archive) {
    final filePath = p.join(targetPath, file.name);
    
    if (file.isFile) {
      final outputFile = File(filePath);
      await outputFile.parent.create(recursive: true);
      await outputFile.writeAsBytes(file.content as List<int>);
    } else {
      await Directory(filePath).create(recursive: true);
    }
  }
}
```

- [ ] **Step 3: 添加 DatabaseService 导入**

确保文件顶部有导入：

```dart
import 'database_service.dart';
```

- [ ] **Step 4: 提交**

```bash
git add lib/services/webdav_service.dart
git commit -m "feat: add image backup and restore support in WebDAV sync"
```

---

## Task 10: 更新 WebDAV 配置页面支持图片同步选项

**Files:**
- Modify: `lib/pages/webdav_config_page.dart`

- [ ] **Step 1: 在 WebDAVConfigNotifier 类中添加含图片同步的方法**

在 `WebDAVConfigNotifier` 类的 `sync` 方法之后添加：

```dart
Future<void> syncWithImages() async {
  if (state.config == null) return;

  state = state.copyWith(syncStatus: SyncStatus.syncing, clearError: true);
  try {
    await _webdavService.uploadBackupWithImages(state.config!);
    state = state.copyWith(
      syncStatus: SyncStatus.idle,
      config: state.config!.copyWith(lastSyncAt: DateTime.now()),
    );
  } catch (e) {
    state = state.copyWith(
      syncStatus: SyncStatus.error,
      error: e.toString(),
    );
  }
}

Future<List<RemoteBackupInfo>> getRemoteBackups() async {
  if (state.config == null) return [];
  return await _webdavService.listRemoteBackups(state.config!);
}

Future<void> restoreBackup(String dbPath, String? imagesPath) async {
  if (state.config == null) return;
  
  state = state.copyWith(syncStatus: SyncStatus.syncing, clearError: true);
  try {
    await _webdavService.downloadAndRestoreWithImages(
      state.config!,
      dbPath,
      imagesPath,
    );
    state = state.copyWith(syncStatus: SyncStatus.idle);
  } catch (e) {
    state = state.copyWith(
      syncStatus: SyncStatus.error,
      error: e.toString(),
    );
  }
}
```

- [ ] **Step 2: 添加状态变量**

在 `_WebDAVConfigPageState` 类中，现有状态变量后添加：

```dart
bool _isSyncingWithImages = false;
bool _showRestoreOptions = false;
List<RemoteBackupInfo> _remoteBackups = [];
```

- [ ] **Step 3: 修改操作按钮区域**

找到操作按钮的 `Row` 组件（约第314-348行），替换为：

```dart
// 操作按钮
Row(
  children: [
    Expanded(
      child: OutlinedButton.icon(
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
    const SizedBox(width: AppSpacing.md),
    Expanded(
      child: ElevatedButton.icon(
        onPressed: _isSyncing || !_enabled ? null : _syncNow,
        icon: _isSyncing
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.sync),
        label: Text(_isSyncing ? '同步中...' : '立即同步'),
      ),
    ),
  ],
),

const SizedBox(height: AppSpacing.md),

// 完整备份按钮（含图片）
SizedBox(
  width: double.infinity,
  child: ElevatedButton.icon(
    onPressed: _isSyncingWithImages || !_enabled ? null : _syncWithImages,
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.primaryContainer,
      foregroundColor: AppColors.primary,
    ),
    icon: _isSyncingWithImages
        ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : const Icon(Icons.cloud_upload),
    label: Text(_isSyncingWithImages ? '备份中...' : '完整备份（含图片）'),
  ),
),

const SizedBox(height: AppSpacing.md),

// 恢复按钮
SizedBox(
  width: double.infinity,
  child: OutlinedButton.icon(
    onPressed: !_enabled ? null : _showRestoreDialog,
    icon: const Icon(Icons.cloud_download),
    label: const Text('从云端恢复'),
  ),
),
```

- [ ] **Step 4: 添加同步含图片方法**

在 `_WebDAVConfigPageState` 类中添加：

```dart
Future<void> _syncWithImages() async {
  setState(() => _isSyncingWithImages = true);
  await ref.read(webdavConfigProvider.notifier).syncWithImages();
  setState(() => _isSyncingWithImages = false);

  if (mounted) {
    final state = ref.read(webdavConfigProvider);
    if (state.syncStatus != SyncStatus.error) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('备份成功（含图片）！')),
      );
    }
  }
}

Future<void> _showRestoreDialog() async {
  setState(() => _isSyncing = true);
  
  try {
    final backups = await ref.read(webdavConfigProvider.notifier).getRemoteBackups();
    
    setState(() {
      _remoteBackups = backups;
      _isSyncing = false;
    });

    if (!mounted) return;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.3,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                children: [
                  Text(
                    '选择备份文件',
                    style: AppTypography.titleLg.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('取消'),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: _remoteBackups.isEmpty
                  ? const Center(child: Text('暂无备份文件'))
                  : ListView.builder(
                      controller: scrollController,
                      itemCount: _remoteBackups.length,
                      itemBuilder: (context, index) {
                        final backup = _remoteBackups[index];
                        final isImageBackup = backup.name.contains('_images.zip');
                        
                        if (isImageBackup) return const SizedBox.shrink();
                        
                        // 查找对应的图片备份
                        final baseName = backup.name.replaceAll('.db', '');
                        final imageBackup = _remoteBackups.firstWhere(
                          (b) => b.name == '${baseName}_images.zip',
                          orElse: () => backup,
                        );
                        
                        return ListTile(
                          leading: const Icon(Icons.backup),
                          title: Text(backup.name),
                          subtitle: Text(
                            '${_formatFileSize(backup.size)} · ${_formatDateTime(backup.modifiedTime)}',
                          ),
                          onTap: () async {
                            Navigator.pop(context);
                            await _restoreBackup(
                              backup.path,
                              imageBackup.name.contains('.zip') ? imageBackup.path : null,
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  } catch (e) {
    setState(() => _isSyncing = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('获取备份列表失败: $e')),
      );
    }
  }
}

Future<void> _restoreBackup(String dbPath, String? imagesPath) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('确认恢复'),
      content: const Text('恢复将覆盖当前数据，此操作不可撤销。确定要继续吗？'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.error,
          ),
          child: const Text('确认恢复'),
        ),
      ],
    ),
  );

  if (confirmed != true) return;

  setState(() => _isSyncing = true);
  
  try {
    await ref.read(webdavConfigProvider.notifier).restoreBackup(dbPath, imagesPath);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('恢复成功！请重启应用')),
      );
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('恢复失败: $e')),
      );
    }
  } finally {
    setState(() => _isSyncing = false);
  }
}

String _formatFileSize(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}
```

- [ ] **Step 5: 提交**

```bash
git add lib/pages/webdav_config_page.dart
git commit -m "feat: add image sync and restore UI in WebDAV config page"
```

---

## Task 11: 清理 JSON 导出相关代码

**Files:**
- Modify: `lib/services/backup_service.dart`

- [ ] **Step 1: 删除 exportToJsonFile 方法**

删除 `exportToJsonFile` 方法（约第106-131行）。

- [ ] **Step 2: 删除 importFromJsonFile 方法**

删除 `importFromJsonFile` 方法（约第133-148行）。

- [ ] **Step 3: 删除辅助方法**

删除 `_mapToJsonString` 和 `_parseJsonString` 方法。

- [ ] **Step 4: 删除 dart:convert 导入**

删除文件顶部的 `import 'dart:convert';`

- [ ] **Step 5: 提交**

```bash
git add lib/services/backup_service.dart
git commit -m "refactor: remove JSON export/import methods from BackupService"
```

---

## Task 12: 从 DatabaseService 删除 JSON 导出导入方法

**Files:**
- Modify: `lib/services/database_service.dart`

- [ ] **Step 1: 删除 exportAllData 方法**

删除 `exportAllData` 方法（约第550-574行）。

- [ ] **Step 2: 删除 importAllData 方法**

删除 `importAllData` 方法（约第577-633行）。

- [ ] **Step 3: 提交**

```bash
git add lib/services/database_service.dart
git commit -m "refactor: remove JSON export/import methods from DatabaseService"
```

---

## Task 13: 运行测试验证功能

**Files:**
- Test: `test/widget_test.dart`

- [ ] **Step 1: 运行现有测试**

Run: `flutter test`
Expected: 所有测试通过

- [ ] **Step 2: 运行应用进行手动测试**

Run: `flutter run`
测试场景：
1. 添加物品 → 输入名称 → 失焦后查看是否显示相似物品提示
2. 点击图片区域 → 查看是否显示推荐图片选项
3. 添加物品并上传图片 → 再添加同名物品 → 查看图片推荐是否正确
4. WebDAV 备份恢复 → 验证图片是否正确同步

- [ ] **Step 3: 提交最终版本**

```bash
git add -A
git commit -m "feat: complete product image library and history data reuse feature"
```

---

## 实现顺序总结

1. Task 1 - 添加依赖
2. Task 2 - 创建模型
3. Task 3 - 扩展数据库
4. Task 4 - 创建服务
5. Task 5 - 扩展 Provider
6. Task 6 - 历史数据复用 UI
7. Task 7 - 产品图推荐 UI
8. Task 8 - 保存时同步产品图
9. Task 9-10 - WebDAV 同步扩展
10. Task 11-12 - 清理旧代码
11. Task 13 - 测试验证
