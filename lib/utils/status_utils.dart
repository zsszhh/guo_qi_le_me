import '../utils/constants.dart';

/// 状态计算工具
class StatusUtils {
  StatusUtils._();

  /// 根据过期日期计算物品状态
  static ItemStatus calculateStatus(DateTime expiryDate) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final expiry = DateTime(expiryDate.year, expiryDate.month, expiryDate.day);
    final daysRemaining = expiry.difference(today).inDays;

    if (daysRemaining <= 0) {
      return ItemStatus.expired;
    } else if (daysRemaining <= AppConstants.urgentDaysThreshold) {
      return ItemStatus.urgent;
    } else if (daysRemaining <= AppConstants.expiringSoonDaysThreshold) {
      return ItemStatus.expiringSoon;
    } else {
      return ItemStatus.normal;
    }
  }

  /// 获取状态颜色值
  static int getStatusColor(ItemStatus status) {
    switch (status) {
      case ItemStatus.normal:
        return 0xFF006D36; // Primary Green
      case ItemStatus.expiringSoon:
        return 0xFF8F4E00; // Warning Orange
      case ItemStatus.urgent:
        return 0xFFB91A24; // Critical Red
      case ItemStatus.expired:
        return 0xFFBA1A1A; // Error Red
      case ItemStatus.consumed:
        return 0xFF4ADE80; // Consumed Green
    }
  }

  /// 获取状态图标
  static String getStatusIcon(ItemStatus status) {
    switch (status) {
      case ItemStatus.normal:
        return '✅';
      case ItemStatus.expiringSoon:
        return '⚠️';
      case ItemStatus.urgent:
        return '🔴';
      case ItemStatus.expired:
        return '❌';
      case ItemStatus.consumed:
        return '✓';
    }
  }
}
