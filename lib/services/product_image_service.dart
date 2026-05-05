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
