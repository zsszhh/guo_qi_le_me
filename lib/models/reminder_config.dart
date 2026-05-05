/// 提醒配置实体
class ReminderConfig {
  final String id;
  final bool remind3Days;
  final bool remind7Days;
  final bool remind14Days;
  final bool pushNotification;
  final String reminderTime;
  final bool soundEnabled;
  final String? quietHoursStart;
  final String? quietHoursEnd;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ReminderConfig({
    required this.id,
    this.remind3Days = true,
    this.remind7Days = true,
    this.remind14Days = true,
    this.pushNotification = true,
    this.reminderTime = '09:00',
    this.soundEnabled = true,
    this.quietHoursStart,
    this.quietHoursEnd,
    required this.createdAt,
    required this.updatedAt,
  });

  /// 默认配置
  factory ReminderConfig.defaultConfig(String id) {
    final now = DateTime.now();
    return ReminderConfig(
      id: id,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// 从JSON创建
  factory ReminderConfig.fromJson(Map<String, dynamic> json) {
    return ReminderConfig(
      id: json['id'] as String,
      remind3Days: json['remind_3_days'] as bool? ?? true,
      remind7Days: json['remind_7_days'] as bool? ?? true,
      remind14Days: json['remind_14_days'] as bool? ?? true,
      pushNotification: json['push_notification'] as bool? ?? true,
      reminderTime: json['reminder_time'] as String? ?? '09:00',
      soundEnabled: json['sound_enabled'] as bool? ?? true,
      quietHoursStart: json['quiet_hours_start'] as String?,
      quietHoursEnd: json['quiet_hours_end'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'remind_3_days': remind3Days,
      'remind_7_days': remind7Days,
      'remind_14_days': remind14Days,
      'push_notification': pushNotification,
      'reminder_time': reminderTime,
      'sound_enabled': soundEnabled,
      'quiet_hours_start': quietHoursStart,
      'quiet_hours_end': quietHoursEnd,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// 复制并修改
  ReminderConfig copyWith({
    String? id,
    bool? remind3Days,
    bool? remind7Days,
    bool? remind14Days,
    bool? pushNotification,
    String? reminderTime,
    bool? soundEnabled,
    String? quietHoursStart,
    String? quietHoursEnd,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ReminderConfig(
      id: id ?? this.id,
      remind3Days: remind3Days ?? this.remind3Days,
      remind7Days: remind7Days ?? this.remind7Days,
      remind14Days: remind14Days ?? this.remind14Days,
      pushNotification: pushNotification ?? this.pushNotification,
      reminderTime: reminderTime ?? this.reminderTime,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      quietHoursStart: quietHoursStart ?? this.quietHoursStart,
      quietHoursEnd: quietHoursEnd ?? this.quietHoursEnd,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
