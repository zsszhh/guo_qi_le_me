/// 自定义选项类型
enum CustomOptionType {
  category('分类'),
  location('存放位置'),
  unit('单位'),
  subCategory('子分类');

  final String label;
  const CustomOptionType(this.label);
}

/// 自定义选项实体
class CustomOption {
  final String id;
  final CustomOptionType type;
  final String? category;    // 用于区分子分类属于哪个分类
  final String value;
  final int usageCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CustomOption({
    required this.id,
    required this.type,
    this.category,
    required this.value,
    this.usageCount = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  /// 从JSON创建
  factory CustomOption.fromJson(Map<String, dynamic> json) {
    return CustomOption(
      id: json['id'] as String,
      type: CustomOptionType.values.firstWhere(
        (e) => e.name == json['option_type'],
        orElse: () => CustomOptionType.category,
      ),
      category: json['category'] as String?,
      value: json['value'] as String,
      usageCount: json['usage_count'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'option_type': type.name,
      'category': category,
      'value': value,
      'usage_count': usageCount,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// 复制并修改
  CustomOption copyWith({
    String? id,
    CustomOptionType? type,
    String? category,
    String? value,
    int? usageCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CustomOption(
      id: id ?? this.id,
      type: type ?? this.type,
      category: category ?? this.category,
      value: value ?? this.value,
      usageCount: usageCount ?? this.usageCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
