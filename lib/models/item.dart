import 'package:flutter/foundation.dart';
import '../utils/constants.dart';

/// 物品实体
class Item {
  final String id;
  final String name;
  final String category;         // 改为字符串支持自定义分类
  final String? subCategory;
  final String? brand;
  final String? specification;
  final DateTime purchaseDate;
  final DateTime expiryDate;
  final DateTime? openedDate;
  final int quantity;
  final String unit;
  final String? location;
  final String? notes;
  final String? imageUrl;
  final ItemStatus status;
  final double? aiConfidence;
  final DateTime createdAt;
  final DateTime updatedAt;

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

  /// 从JSON创建（带安全解析）
  factory Item.fromJson(Map<String, dynamic> json) {
    // 验证必需字段
    if (json['id'] == null || (json['id'] as String).isEmpty) {
      throw const FormatException('Item JSON 缺少必需字段: id');
    }
    if (json['name'] == null || (json['name'] as String).isEmpty) {
      throw const FormatException('Item JSON 缺少必需字段: name');
    }

    // 安全解析日期（带日志记录）
    DateTime parseDate(String? value, DateTime defaultValue, String fieldName) {
      if (value == null || value.isEmpty) return defaultValue;
      try {
        return DateTime.parse(value);
      } catch (e) {
        debugPrint('警告: 解析日期字段 "$fieldName" 失败，值: "$value"，使用默认值');
        return defaultValue;
      }
    }

    final now = DateTime.now();

    return Item(
      id: json['id'] as String,
      name: json['name'] as String,
      category: json['category'] as String? ?? PresetCategories.food,
      subCategory: json['sub_category'] as String?,
      brand: json['brand'] as String?,
      specification: json['specification'] as String?,
      purchaseDate: parseDate(json['purchase_date'] as String?, now, 'purchase_date'),
      expiryDate: parseDate(json['expiry_date'] as String?, now.add(const Duration(days: 7)), 'expiry_date'),
      openedDate: json['opened_date'] != null
          ? parseDate(json['opened_date'] as String?, now, 'opened_date')
          : null,
      quantity: json['quantity'] as int? ?? 1,
      unit: json['unit'] as String? ?? '个',
      location: json['location'] as String?,
      notes: json['notes'] as String?,
      imageUrl: json['image_url'] as String?,
      status: ItemStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => ItemStatus.normal,
      ),
      aiConfidence: json['ai_confidence'] as double?,
      createdAt: parseDate(json['created_at'] as String?, now, 'created_at'),
      updatedAt: parseDate(json['updated_at'] as String?, now, 'updated_at'),
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'sub_category': subCategory,
      'brand': brand,
      'specification': specification,
      'purchase_date': purchaseDate.toIso8601String(),
      'expiry_date': expiryDate.toIso8601String(),
      'opened_date': openedDate?.toIso8601String(),
      'quantity': quantity,
      'unit': unit,
      'location': location,
      'notes': notes,
      'image_url': imageUrl,
      'status': status.name,
      'ai_confidence': aiConfidence,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// 复制并修改
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
}
