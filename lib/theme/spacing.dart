import 'package:flutter/material.dart';

/// 应用间距定义
/// 基于 8pt rhythm 设计系统
class AppSpacing {
  AppSpacing._();

  // === 基础间距 ===

  /// 超小间距 (4px)
  static const double xs = 4.0;

  /// 基础单位 (8px)
  static const double base = 8.0;

  /// 小间距 (12px)
  static const double sm = 12.0;

  /// 中等间距 (16px)
  static const double md = 16.0;

  /// 大间距 (24px)
  static const double lg = 24.0;

  /// 超大间距 (32px)
  static const double xl = 32.0;

  // === 特殊间距 ===

  /// 页面边距 (20px)
  static const double containerMargin = 20.0;

  /// 卡片间距 (16px)
  static const double gutter = 16.0;

  // === EdgeInsets 便捷方法 ===

  /// 页面水平边距
  static EdgeInsets get horizontalPage => const EdgeInsets.symmetric(horizontal: containerMargin);

  /// 页面全部边距
  static EdgeInsets get page => const EdgeInsets.all(containerMargin);

  /// 卡片内边距
  static EdgeInsets get card => const EdgeInsets.all(md);

  /// 小内边距
  static EdgeInsets get small => const EdgeInsets.all(sm);

  /// 超小内边距
  static EdgeInsets get extraSmall => const EdgeInsets.all(xs);
}

/// 圆角定义
class AppRadius {
  AppRadius._();

  /// 小圆角 (4px)
  static const double sm = 4.0;

  /// 默认圆角 (8px)
  static const double defaultValue = 8.0;

  /// 中等圆角 (12px)
  static const double md = 12.0;

  /// 大圆角 (16px)
  static const double lg = 16.0;

  /// 超大圆角 (24px)
  static const double xl = 24.0;

  /// 全圆角
  static const double full = 9999.0;

  // === BorderRadius 便捷方法 ===

  static BorderRadius get small => BorderRadius.circular(sm);
  static BorderRadius get defaultBorder => BorderRadius.circular(defaultValue);
  static BorderRadius get medium => BorderRadius.circular(md);
  static BorderRadius get large => BorderRadius.circular(lg);
  static BorderRadius get extraLarge => BorderRadius.circular(xl);
  static BorderRadius get fullBorder => BorderRadius.circular(full);
}

/// 阴影定义
class AppShadows {
  AppShadows._();

  /// 卡片阴影
  static List<BoxShadow> get card => [
    BoxShadow(
      color: const Color(0xFF000000).withOpacity(0.04),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  /// 按钮阴影
  static List<BoxShadow> get button => [
    BoxShadow(
      color: const Color(0xFF4ADE80).withOpacity(0.25),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
  ];

  /// 底部导航栏阴影
  static List<BoxShadow> get bottomNav => [
    BoxShadow(
      color: const Color(0xFF000000).withOpacity(0.04),
      blurRadius: 20,
      offset: const Offset(0, -4),
    ),
  ];
}
