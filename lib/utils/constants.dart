import 'package:flutter/material.dart';

/// 应用常量定义
class AppConstants {
  AppConstants._();

  /// 应用名称
  static const String appName = '过期了么';

  /// 数据库名称
  static const String databaseName = 'guo_qi_le_me.db';

  /// WebDAV默认远程路径
  static const String webdavDefaultPath = '/guo_qi_le_me';

  /// 默认API超时时间（秒）
  static const int defaultApiTimeout = 30;

  /// 默认同步间隔（分钟）
  static const int defaultSyncInterval = 30;

  /// 状态阈值配置
  static const int urgentDaysThreshold = 3;          // 急需处理阈值（天）
  static const int expiringSoonDaysThreshold = 14;   // 即将过期阈值（天）
  static const int badgeDaysThreshold = 3;           // 角标显示阈值（天）
  static const int warningDaysThreshold = 7;         // 警告显示阈值（天）

  /// AI分析缓存有效期（天）
  static const int aiCacheValidDays = 30;

  /// 搜索结果最大数量
  static const int searchResultLimit = 10;

  /// 最近物品显示数量
  static const int recentItemsLimit = 5;
}

/// 预设分类（用户可添加更多）
class PresetCategories {
  PresetCategories._();

  static const String food = '食品';
  static const String drug = '药品';
  static const String cosmetic = '化妆品';
  static const String daily = '日用品';
  static const String other = '其他';

  static List<String> get defaults => [food, drug, cosmetic, daily, other];

  /// 根据分类名称返回对应图标
  static IconData getIcon(String? category) {
    switch (category) {
      case food:
        return Icons.restaurant;
      case drug:
        return Icons.medication;
      case cosmetic:
        return Icons.face_retouching_natural;
      case daily:
        return Icons.home;
      default:
        return Icons.inventory_2;
    }
  }

  /// 根据分类名称返回默认保质期（天数）
  static int getDefaultShelfLife(String? category) {
    switch (category) {
      case food:
        return 30;
      case drug:
        return 365;
      case cosmetic:
        return 365;
      case daily:
        return 730;
      default:
        return 90;
    }
  }
}

/// 物品状态
enum ItemStatus {
  normal('正常'),
  expiringSoon('即将过期'),
  urgent('急需处理'),
  expired('已过期'),
  consumed('已使用');

  final String label;
  const ItemStatus(this.label);

  String get displayName => label;
}

/// AI模型提供商
enum AIProvider {
  doubao('豆包', isPreset: true),
  custom('自定义', isPreset: false);

  final String name;
  final bool isPreset;
  const AIProvider(this.name, {this.isPreset = false});
}

/// 提醒类型
enum ReminderType {
  threeDays('3天', 3),
  sevenDays('7天', 7),
  fourteenDays('14天', 14),
  expired('已过期', 0);

  final String label;
  final int days;
  const ReminderType(this.label, this.days);
}
