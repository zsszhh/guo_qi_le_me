import '../utils/constants.dart';

/// 提醒类型枚举
enum ReminderType {
  threeDays,
  sevenDays,
  fourteenDays,
  expired,
}

/// 提醒状态枚举
enum ReminderStatus {
  pending,
  read,
  actioned,
}

/// 提醒记录实体
class ReminderLog {
  final String id;
  final String itemId;
  final ReminderType reminderType;
  final ReminderStatus status;
  final DateTime notifiedAt;
  final DateTime? readAt;
  final DateTime? actionedAt;

  const ReminderLog({
    required this.id,
    required this.itemId,
    required this.reminderType,
    required this.status,
    required this.notifiedAt,
    this.readAt,
    this.actionedAt,
  });

  /// 从JSON创建
  factory ReminderLog.fromJson(Map<String, dynamic> json) {
    return ReminderLog(
      id: json['id'] as String,
      itemId: json['item_id'] as String,
      reminderType: ReminderType.values.firstWhere(
        (e) => e.name == json['reminder_type'],
        orElse: () => ReminderType.threeDays,
      ),
      status: ReminderStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => ReminderStatus.pending,
      ),
      notifiedAt: DateTime.parse(json['notified_at'] as String),
      readAt: json['read_at'] != null
          ? DateTime.parse(json['read_at'] as String)
          : null,
      actionedAt: json['actioned_at'] != null
          ? DateTime.parse(json['actioned_at'] as String)
          : null,
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'item_id': itemId,
      'reminder_type': reminderType.name,
      'status': status.name,
      'notified_at': notifiedAt.toIso8601String(),
      'read_at': readAt?.toIso8601String(),
      'actioned_at': actionedAt?.toIso8601String(),
    };
  }

  /// 复制并修改
  ReminderLog copyWith({
    String? id,
    String? itemId,
    ReminderType? reminderType,
    ReminderStatus? status,
    DateTime? notifiedAt,
    DateTime? readAt,
    DateTime? actionedAt,
  }) {
    return ReminderLog(
      id: id ?? this.id,
      itemId: itemId ?? this.itemId,
      reminderType: reminderType ?? this.reminderType,
      status: status ?? this.status,
      notifiedAt: notifiedAt ?? this.notifiedAt,
      readAt: readAt ?? this.readAt,
      actionedAt: actionedAt ?? this.actionedAt,
    );
  }
}
