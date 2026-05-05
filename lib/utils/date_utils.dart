/// 日期工具类
class DateUtils {
  DateUtils._();

  /// 计算剩余天数
  static int daysRemaining(DateTime expiryDate) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final expiry = DateTime(expiryDate.year, expiryDate.month, expiryDate.day);
    return expiry.difference(today).inDays;
  }

  /// 判断是否已过期
  static bool isExpired(DateTime expiryDate) {
    return daysRemaining(expiryDate) <= 0;
  }

  /// 判断是否即将过期（3天内）
  static bool isUrgent(DateTime expiryDate) {
    final days = daysRemaining(expiryDate);
    return days > 0 && days <= 3;
  }

  /// 判断是否即将过期（14天内）
  static bool isExpiringSoon(DateTime expiryDate) {
    final days = daysRemaining(expiryDate);
    return days > 3 && days <= 14;
  }

  /// 判断是否正常
  static bool isNormal(DateTime expiryDate) {
    return daysRemaining(expiryDate) > 14;
  }

  /// 格式化日期显示
  static String formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// 格式化剩余天数显示
  static String formatDaysRemaining(int days) {
    if (days < 0) {
      return '已过期${-days}天';
    } else if (days == 0) {
      return '今天过期';
    } else {
      return '$days天后过期';
    }
  }

  /// 格式化日期为文件名（用于备份文件）
  static String formatDateForFileName(DateTime date) {
    return '${date.year}${_pad(date.month)}${_pad(date.day)}_${_pad(date.hour)}${_pad(date.minute)}${_pad(date.second)}';
  }

  static String _pad(int n) => n.toString().padLeft(2, '0');
}
