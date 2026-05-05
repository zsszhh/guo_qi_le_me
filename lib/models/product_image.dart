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
