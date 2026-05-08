/// 开封保质期规则
class ExpiryRule {
  final String category;
  final String? subCategory;
  final int daysAfterOpened;
  final String? storageTip;

  const ExpiryRule({
    required this.category,
    this.subCategory,
    required this.daysAfterOpened,
    this.storageTip,
  });
}

/// 开封保质期规则库
class ExpiryRules {
  ExpiryRules._();

  /// 默认开封后天数（全局兜底）
  static const int defaultDaysAfterOpened = 7;

  /// 预设规则列表
  static const List<ExpiryRule> rules = [
    // 食品 - 乳制品
    ExpiryRule(category: '食品', subCategory: '牛奶', daysAfterOpened: 3, storageTip: '需冷藏'),
    ExpiryRule(category: '食品', subCategory: '酸奶', daysAfterOpened: 3, storageTip: '需冷藏'),
    ExpiryRule(category: '食品', subCategory: '奶酪', daysAfterOpened: 7, storageTip: '需冷藏'),

    // 食品 - 蛋类
    ExpiryRule(category: '食品', subCategory: '鸡蛋', daysAfterOpened: 14, storageTip: '常温或冷藏'),

    // 食品 - 调味品
    ExpiryRule(category: '食品', subCategory: '酱油', daysAfterOpened: 90, storageTip: '阴凉处'),
    ExpiryRule(category: '食品', subCategory: '蚝油', daysAfterOpened: 30, storageTip: '需冷藏'),
    ExpiryRule(category: '食品', subCategory: '醋', daysAfterOpened: 180, storageTip: '阴凉处'),
    ExpiryRule(category: '食品', subCategory: '番茄酱', daysAfterOpened: 30, storageTip: '需冷藏'),
    ExpiryRule(category: '食品', subCategory: '蛋黄酱', daysAfterOpened: 60, storageTip: '需冷藏'),
    ExpiryRule(category: '食品', subCategory: '沙拉酱', daysAfterOpened: 30, storageTip: '需冷藏'),

    // 食品 - 烘焙
    ExpiryRule(category: '食品', subCategory: '面包', daysAfterOpened: 3, storageTip: '密封保存'),
    ExpiryRule(category: '食品', subCategory: '蛋糕', daysAfterOpened: 2, storageTip: '需冷藏'),

    // 食品 - 零食
    ExpiryRule(category: '食品', subCategory: '薯片', daysAfterOpened: 7, storageTip: '密封保存'),
    ExpiryRule(category: '食品', subCategory: '饼干', daysAfterOpened: 14, storageTip: '密封保存'),

    // 食品 - 肉类
    ExpiryRule(category: '食品', subCategory: '火腿', daysAfterOpened: 7, storageTip: '需冷藏'),
    ExpiryRule(category: '食品', subCategory: '香肠', daysAfterOpened: 7, storageTip: '需冷藏'),

    // 食品 - 默认规则
    ExpiryRule(category: '食品', daysAfterOpened: 7),

    // 药品
    ExpiryRule(category: '药品', subCategory: '眼药水', daysAfterOpened: 28, storageTip: '避光保存'),
    ExpiryRule(category: '药品', subCategory: '糖浆', daysAfterOpened: 30, storageTip: '密封阴凉'),
    ExpiryRule(category: '药品', subCategory: '滴耳液', daysAfterOpened: 30, storageTip: '避光保存'),
    ExpiryRule(category: '药品', subCategory: '滴鼻液', daysAfterOpened: 30, storageTip: '避光保存'),
    ExpiryRule(category: '药品', subCategory: '软膏', daysAfterOpened: 60, storageTip: '密封阴凉'),

    // 药品 - 默认规则
    ExpiryRule(category: '药品', daysAfterOpened: 30, storageTip: '参照说明书'),

    // 化妆品
    ExpiryRule(category: '化妆品', subCategory: '面霜', daysAfterOpened: 180, storageTip: '避光保存'),
    ExpiryRule(category: '化妆品', subCategory: '精华液', daysAfterOpened: 90, storageTip: '避光保存'),
    ExpiryRule(category: '化妆品', subCategory: '眼霜', daysAfterOpened: 90, storageTip: '避光保存'),
    ExpiryRule(category: '化妆品', subCategory: '面膜', daysAfterOpened: 30, storageTip: '密封保存'),
    ExpiryRule(category: '化妆品', subCategory: '口红', daysAfterOpened: 365, storageTip: '避光保存'),
    ExpiryRule(category: '化妆品', subCategory: '睫毛膏', daysAfterOpened: 90, storageTip: '避免交叉污染'),

    // 化妆品 - 默认规则
    ExpiryRule(category: '化妆品', daysAfterOpened: 90, storageTip: '参照包装说明'),

    // 日用品
    ExpiryRule(category: '日用品', subCategory: '洗发水', daysAfterOpened: 365, storageTip: '常温保存'),
    ExpiryRule(category: '日用品', subCategory: '沐浴露', daysAfterOpened: 365, storageTip: '常温保存'),
    ExpiryRule(category: '日用品', subCategory: '牙膏', daysAfterOpened: 180, storageTip: '常温保存'),

    // 日用品 - 默认规则
    ExpiryRule(category: '日用品', daysAfterOpened: 180),
  ];

  /// 根据分类和子分类匹配规则
  /// 返回匹配的规则，如果没有精确匹配则返回分类默认规则
  static ExpiryRule? findRule(String category, String? subCategory) {
    // 1. 精确匹配：主分类 + 子分类
    if (subCategory != null && subCategory.isNotEmpty) {
      for (final rule in rules) {
        if (rule.category == category && rule.subCategory == subCategory) {
          return rule;
        }
      }
    }

    // 2. 分类默认：仅主分类
    for (final rule in rules) {
      if (rule.category == category && rule.subCategory == null) {
        return rule;
      }
    }

    // 3. 无匹配规则
    return null;
  }

  /// 获取建议天数（带默认值）
  static int getSuggestedDays(String category, String? subCategory) {
    final rule = findRule(category, subCategory);
    return rule?.daysAfterOpened ?? defaultDaysAfterOpened;
  }

  /// 获取存储提示
  static String? getStorageTip(String category, String? subCategory) {
    final rule = findRule(category, subCategory);
    return rule?.storageTip;
  }
}
