import 'package:flutter/material.dart';

/// 应用字体样式定义
/// 基于 stitch 设计系统
class AppTypography {
  AppTypography._();

  // === 预定义文字样式 ===

  /// Display - 大标题 (32px)
  static const TextStyle display = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    height: 40 / 32,
    letterSpacing: -0.02,
  );

  /// Headline MD - 页面标题 (24px)
  static const TextStyle headlineMd = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 32 / 24,
    letterSpacing: -0.01,
  );

  /// Title LG - 卡片标题 (20px)
  static const TextStyle titleLg = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 28 / 20,
  );

  /// Body Base - 正文 (16px)
  static const TextStyle bodyBase = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 24 / 16,
  );

  /// Body SM - 辅助文字 (14px)
  static const TextStyle bodySm = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 20 / 14,
  );

  /// Label Caps - 标签 (12px, 大写)
  static const TextStyle labelCaps = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w700,
    height: 16 / 12,
    letterSpacing: 0.05,
  );

  // === TextTheme 配置 ===

  static TextTheme get textTheme => TextTheme(
    displayLarge: display,
    displayMedium: display.copyWith(fontSize: 28),
    displaySmall: display.copyWith(fontSize: 24),
    headlineLarge: headlineMd.copyWith(fontSize: 28),
    headlineMedium: headlineMd,
    headlineSmall: headlineMd.copyWith(fontSize: 20),
    titleLarge: titleLg,
    titleMedium: titleLg.copyWith(fontSize: 16),
    titleSmall: titleLg.copyWith(fontSize: 14),
    bodyLarge: bodyBase,
    bodyMedium: bodyBase.copyWith(fontSize: 14),
    bodySmall: bodySm,
    labelLarge: labelCaps.copyWith(fontSize: 14),
    labelMedium: labelCaps,
    labelSmall: labelCaps.copyWith(fontSize: 10),
  );
}
