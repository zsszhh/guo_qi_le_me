import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/item.dart';
import '../models/reminder_config.dart';
import '../models/reminder_log.dart';
import '../services/database_service.dart';

/// 通知导航回调类型
typedef NotificationNavigationCallback = void Function(String itemId);

/// 通知服务
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  final DatabaseService _dbService = DatabaseService();

  bool _initialized = false;

  /// 通知点击导航回调
  NotificationNavigationCallback? onNotificationTapped;

  /// 设置通知点击回调
  void setNavigationCallback(NotificationNavigationCallback callback) {
    onNotificationTapped = callback;
  }

  /// 初始化通知服务
  Future<void> initialize() async {
    if (_initialized) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iOSSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iOSSettings,
    );

    await _notifications.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    _initialized = true;
  }

  /// 请求通知权限
  Future<bool> requestPermission() async {
    final android = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final ios = _notifications.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();

    bool granted = true;

    if (android != null) {
      granted = await android.requestNotificationsPermission() ?? false;
    }

    if (ios != null) {
      final iosGranted = await ios.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      granted = granted && (iosGranted ?? false);
    }

    return granted;
  }

  /// 检查并发送提醒
  Future<void> checkAndSendReminders() async {
    final config = await _dbService.getReminderConfig();
    if (config == null) return;

    final items = await _dbService.getAllItems();

    for (final item in items) {
      await _checkItemReminders(item, config);
    }
  }

  /// 检查单个物品的提醒
  Future<void> _checkItemReminders(Item item, ReminderConfig config) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final expiryDate = DateTime(item.expiryDate.year, item.expiryDate.month, item.expiryDate.day);
    final daysRemaining = expiryDate.difference(today).inDays;

    // 获取已发送的提醒记录
    final existingLogs = await _dbService.getReminderLogsByItemId(item.id);
    final sentTypes = existingLogs.map((log) => log.reminderType).toSet();

    // 检查3天提醒
    if (config.remind3Days && daysRemaining == 3 && !sentTypes.contains(ReminderType.threeDays)) {
      await _sendReminder(item, ReminderType.threeDays, config);
    }

    // 检查7天提醒
    if (config.remind7Days && daysRemaining == 7 && !sentTypes.contains(ReminderType.sevenDays)) {
      await _sendReminder(item, ReminderType.sevenDays, config);
    }

    // 检查14天提醒
    if (config.remind14Days && daysRemaining == 14 && !sentTypes.contains(ReminderType.fourteenDays)) {
      await _sendReminder(item, ReminderType.fourteenDays, config);
    }

    // 检查过期提醒
    if (daysRemaining <= 0 && !sentTypes.contains(ReminderType.expired)) {
      await _sendReminder(item, ReminderType.expired, config);
    }
  }

  /// 发送提醒
  Future<void> _sendReminder(Item item, ReminderType type, ReminderConfig config) async {
    if (!config.pushNotification) return;

    final title = _getNotificationTitle(type);
    final body = _getNotificationBody(item, type);

    // 发送通知
    await _showNotification(
      id: item.id.hashCode,
      title: title,
      body: body,
      payload: item.id,
    );

    // 记录提醒日志
    final log = ReminderLog(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      itemId: item.id,
      reminderType: type,
      status: ReminderStatus.pending,
      notifiedAt: DateTime.now(),
    );

    await _dbService.insertReminderLog(log);
  }

  /// 显示通知
  Future<void> _showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      'expiry_reminder',
      '过期提醒',
      channelDescription: '物品过期提醒通知',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: details,
      payload: payload,
    );
  }

  /// 获取通知标题
  String _getNotificationTitle(ReminderType type) {
    switch (type) {
      case ReminderType.threeDays:
        return '⚠️ 即将过期提醒';
      case ReminderType.sevenDays:
        return '⏰ 过期提醒';
      case ReminderType.fourteenDays:
        return '📅 过期提醒';
      case ReminderType.expired:
        return '❌ 已过期提醒';
    }
  }

  /// 获取通知内容
  String _getNotificationBody(Item item, ReminderType type) {
    switch (type) {
      case ReminderType.threeDays:
        return '${item.name} 将在3天后过期，请尽快使用';
      case ReminderType.sevenDays:
        return '${item.name} 将在7天后过期';
      case ReminderType.fourteenDays:
        return '${item.name} 将在14天后过期';
      case ReminderType.expired:
        return '${item.name} 已过期，请及时处理';
    }
  }

  /// 通知点击处理
  void _onNotificationTapped(NotificationResponse response) {
    final payload = response.payload;
    if (payload != null && onNotificationTapped != null) {
      onNotificationTapped!(payload);
    }
  }

  /// 取消通知
  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id: id);
  }

  /// 取消所有通知
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }
}

/// 通知服务 Provider
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});
