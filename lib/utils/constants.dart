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
  static const int urgentDaysThreshold = 3;
  static const int expiringSoonDaysThreshold = 14;
}

/// 预设分类（用户可添加更多）
class PresetCategories {
  PresetCategories._();

  static const String food = '食品';
  static const String drug = '药品';

  static List<String> get defaults => [food, drug];
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
