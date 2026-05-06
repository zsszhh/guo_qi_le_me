import 'package:workmanager/workmanager.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'notification_service.dart';

/// 后台任务服务
class BackgroundService {
  static final BackgroundService _instance = BackgroundService._internal();
  factory BackgroundService() => _instance;
  BackgroundService._internal();

  static const String _taskName = 'expiry_reminder_check';
  static const String _taskTag = 'expiry_reminder';

  final NotificationService _notificationService = NotificationService();

  /// 初始化后台任务服务
  Future<void> initialize() async {
    await Workmanager().initialize(
      _callbackDispatcher,
    );
  }

  /// 注册定时提醒任务
  /// [reminderTime] 提醒时间，格式 'HH:mm'，如 '09:00'
  Future<void> scheduleDailyReminder({String reminderTime = '09:00'}) async {
    // 解析时间
    final parts = reminderTime.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts.length > 1 ? parts[1] : '0');

    // 取消现有任务
    await Workmanager().cancelByTag(_taskTag);

    // 注册新的定时任务
    await Workmanager().registerPeriodicTask(
      _taskName,
      _taskName,
      tag: _taskTag,
      frequency: const Duration(hours: 24), // 每24小时执行一次
      initialDelay: _calculateInitialDelay(hour, minute),
      constraints: Constraints(
        networkType: NetworkType.notRequired,
        requiresBatteryNotLow: false,
        requiresCharging: false,
        requiresDeviceIdle: false,
        requiresStorageNotLow: false,
      ),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.update,
    );
  }

  /// 计算初始延迟时间
  Duration _calculateInitialDelay(int hour, int minute) {
    final now = DateTime.now();
    var scheduledTime = DateTime(now.year, now.month, now.day, hour, minute);

    // 如果今天的时间已过，则从明天开始
    if (scheduledTime.isBefore(now)) {
      scheduledTime = scheduledTime.add(const Duration(days: 1));
    }

    return scheduledTime.difference(now);
  }

  /// 取消所有后台任务
  Future<void> cancelAllTasks() async {
    await Workmanager().cancelAll();
  }

  /// 执行提醒检查（供后台任务回调使用）
  Future<void> performReminderCheck() async {
    await _notificationService.checkAndSendReminders();
    await _notificationService.updateBadge();
  }
}

/// 后台任务回调入口点（必须是顶级函数）
@pragma('vm:entry-point')
void _callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    // 初始化通知服务
    final notificationService = NotificationService();
    await notificationService.initialize();

    // 检查并发送提醒
    await notificationService.checkAndSendReminders();

    // 更新角标
    await notificationService.updateBadge();

    return Future.value(true);
  });
}

/// 后台服务 Provider
final backgroundServiceProvider = Provider<BackgroundService>((ref) {
  return BackgroundService();
});
