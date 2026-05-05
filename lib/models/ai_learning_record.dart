import '../utils/constants.dart';

/// AI学习记录实体
class AILearningRecord {
  final String id;
  final String itemName;
  final String category;           // 改为字符串支持自定义分类
  final String? subCategory;
  final String? brand;
  final int typicalExpiryDays;
  final int usageCount;
  final DateTime lastUsedAt;
  final DateTime createdAt;

  const AILearningRecord({
    required this.id,
    required this.itemName,
    required this.category,
    this.subCategory,
    this.brand,
    required this.typicalExpiryDays,
    this.usageCount = 1,
    required this.lastUsedAt,
    required this.createdAt,
  });

  /// 从JSON创建
  factory AILearningRecord.fromJson(Map<String, dynamic> json) {
    return AILearningRecord(
      id: json['id'] as String,
      itemName: json['item_name'] as String,
      category: json['category'] as String? ?? PresetCategories.food,
      subCategory: json['sub_category'] as String?,
      brand: json['brand'] as String?,
      typicalExpiryDays: json['typical_expiry_days'] as int? ?? 7,
      usageCount: json['usage_count'] as int? ?? 1,
      lastUsedAt: DateTime.parse(json['last_used_at'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'item_name': itemName,
      'category': category,
      'sub_category': subCategory,
      'brand': brand,
      'typical_expiry_days': typicalExpiryDays,
      'usage_count': usageCount,
      'last_used_at': lastUsedAt.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// 复制并修改
  AILearningRecord copyWith({
    String? id,
    String? itemName,
    String? category,
    String? subCategory,
    String? brand,
    int? typicalExpiryDays,
    int? usageCount,
    DateTime? lastUsedAt,
    DateTime? createdAt,
  }) {
    return AILearningRecord(
      id: id ?? this.id,
      itemName: itemName ?? this.itemName,
      category: category ?? this.category,
      subCategory: subCategory ?? this.subCategory,
      brand: brand ?? this.brand,
      typicalExpiryDays: typicalExpiryDays ?? this.typicalExpiryDays,
      usageCount: usageCount ?? this.usageCount,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
