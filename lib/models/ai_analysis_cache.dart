/// AI保质期分析缓存模型
///
/// 用于缓存AI对物品保质期的分析结果，避免重复请求AI服务
class AIAnalysisCache {
  /// 缓存记录的唯一标识
  final String id;

  /// 缓存键，格式: 分类_子分类_开封状态
  final String cacheKey;

  /// AI分析结果文本
  final String analysisText;

  /// 缓存创建时间
  final DateTime createdAt;

  const AIAnalysisCache({
    required this.id,
    required this.cacheKey,
    required this.analysisText,
    required this.createdAt,
  });

  /// 生成缓存Key
  ///
  /// [category] 物品分类
  /// [subCategory] 子分类（可选）
  /// [isOpened] 是否已开封
  /// 返回格式: 分类_子分类_开封状态
  static String generateKey(String category, String? subCategory, bool isOpened) {
    final parts = [category];
    if (subCategory != null && subCategory.isNotEmpty) {
      parts.add(subCategory);
    }
    parts.add(isOpened ? '已开封' : '未开封');
    return parts.join('_');
  }

  /// 从JSON创建实例
  factory AIAnalysisCache.fromJson(Map<String, dynamic> json) {
    return AIAnalysisCache(
      id: json['id'] as String,
      cacheKey: json['cache_key'] as String,
      analysisText: json['analysis_text'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'cache_key': cacheKey,
      'analysis_text': analysisText,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// 复制并修改属性
  AIAnalysisCache copyWith({
    String? id,
    String? cacheKey,
    String? analysisText,
    DateTime? createdAt,
  }) {
    return AIAnalysisCache(
      id: id ?? this.id,
      cacheKey: cacheKey ?? this.cacheKey,
      analysisText: analysisText ?? this.analysisText,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'AIAnalysisCache(id: $id, cacheKey: $cacheKey, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AIAnalysisCache && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
