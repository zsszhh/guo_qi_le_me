import 'dart:async';
import 'package:flutter/material.dart';
import 'app.dart';
import 'services/notification_service.dart';
import 'services/background_service.dart';
import 'services/database_service.dart';

/// 全局导航键（用于通知点击导航）
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  // 全局错误处理
  runZonedGuarded<Future<void>>(() async {
    // 捕获 Flutter 框架错误
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      debugPrint('Flutter Error: ${details.exception}');
      debugPrint('Stack trace: ${details.stack}');
    };

    WidgetsFlutterBinding.ensureInitialized();

    // 初始化通知服务
    final notificationService = NotificationService();
    await notificationService.initialize();

    // 请求通知权限
    await notificationService.requestPermission();

    // 设置通知点击回调
    notificationService.setNavigationCallback((itemId) {
      _navigateToItemDetail(itemId);
    });

    // 初始化后台任务服务
    final backgroundService = BackgroundService();
    await backgroundService.initialize();

    // 获取提醒配置并注册定时任务
    final dbService = DatabaseService();
    final reminderConfig = await dbService.getReminderConfig();
    if (reminderConfig != null && reminderConfig.pushNotification) {
      await backgroundService.scheduleDailyReminder(
        reminderTime: reminderConfig.reminderTime,
      );
    }

    // 检查并发送待处理的提醒
    await notificationService.checkAndSendReminders();

    // 更新应用角标
    await notificationService.updateBadge();

    runApp(GuoQilLeMeApp(navigatorKey: navigatorKey));
  }, (error, stackTrace) {
    // 捕获未处理的异步错误
    debugPrint('Unhandled error: $error');
    debugPrint('Stack trace: $stackTrace');
  });
}

/// 导航到物品详情页
void _navigateToItemDetail(String itemId) {
  final context = navigatorKey.currentContext;
  if (context != null) {
    Navigator.of(context).pushNamed('/item-detail', arguments: itemId);
  }
}
