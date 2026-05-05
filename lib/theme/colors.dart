import 'package:flutter/material.dart';

/// 应用颜色定义
/// 基于 stitch_ai_expiry_guardian/guardian_system/DESIGN.md
class AppColors {
  AppColors._();

  // === 主要颜色 ===

  /// 主色 - 新鲜薄荷绿
  static const Color primary = Color(0xFF006D36);

  /// 主色容器
  static const Color primaryContainer = Color(0xFF4ADE80);

  /// 主色固定
  static const Color primaryFixed = Color(0xFF6DFE9C);

  /// 主色固定变暗
  static const Color primaryFixedDim = Color(0xFF4DE082);

  // === 警告色 ===

  /// 警告色 - 暖橙色
  static const Color secondary = Color(0xFF8F4E00);

  /// 警告色容器
  static const Color secondaryContainer = Color(0xFFFEA045);

  /// 警告色固定
  static const Color secondaryFixed = Color(0xFFFFDCC2);

  /// 警告色固定变暗
  static const Color secondaryFixedDim = Color(0xFFFFB77A);

  // === 紧急/错误色 ===

  /// 紧急色 - 柔和红
  static const Color tertiary = Color(0xFFB91A24);

  /// 紧急色容器
  static const Color tertiaryContainer = Color(0xFFFFB0AA);

  /// 错误色
  static const Color error = Color(0xFFBA1A1A);

  /// 错误色容器
  static const Color errorContainer = Color(0xFFFFDAD6);

  // === 表面颜色 ===

  /// 背景
  static const Color background = Color(0xFFF9F9FF);

  /// 表面
  static const Color surface = Color(0xFFF9F9FF);

  /// 表面变暗
  static const Color surfaceDim = Color(0xFFD4DAEA);

  /// 表面变亮
  static const Color surfaceBright = Color(0xFFF9F9FF);

  /// 表面容器 - 最低
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);

  /// 表面容器 - 低
  static const Color surfaceContainerLow = Color(0xFFF1F3FF);

  /// 表面容器
  static const Color surfaceContainer = Color(0xFFE8EEFF);

  /// 表面容器 - 高
  static const Color surfaceContainerHigh = Color(0xFFE3E8F9);

  /// 表面容器 - 最高
  static const Color surfaceContainerHighest = Color(0xFFDDE2F3);

  /// 表面变体
  static const Color surfaceVariant = Color(0xFFDDE2F3);

  /// 表面色调
  static const Color surfaceTint = Color(0xFF006D36);

  // === 文字颜色 ===

  /// 表面文字
  static const Color onSurface = Color(0xFF161C27);

  /// 表面文字变体
  static const Color onSurfaceVariant = Color(0xFF3D4A3E);

  /// 背景文字
  static const Color onBackground = Color(0xFF161C27);

  /// 主色文字
  static const Color onPrimary = Color(0xFFFFFFFF);

  /// 主色容器文字
  static const Color onPrimaryContainer = Color(0xFF005E2D);

  /// 警告色文字
  static const Color onSecondary = Color(0xFFFFFFFF);

  /// 警告色容器文字
  static const Color onSecondaryContainer = Color(0xFF6D3A00);

  /// 紧急色文字
  static const Color onTertiary = Color(0xFFFFFFFF);

  /// 紧急色容器文字
  static const Color onTertiaryContainer = Color(0xFFA50318);

  /// 错误色文字
  static const Color onError = Color(0xFFFFFFFF);

  /// 错误色容器文字
  static const Color onErrorContainer = Color(0xFF93000A);

  // === 反转颜色 ===

  /// 反转表面
  static const Color inverseSurface = Color(0xFF2A303D);

  /// 反转表面文字
  static const Color inverseOnSurface = Color(0xFFECF0FF);

  /// 反转主色
  static const Color inversePrimary = Color(0xFF4DE082);

  // === 边框颜色 ===

  /// 边框
  static const Color outline = Color(0xFF6D7B6D);

  /// 边框变体
  static const Color outlineVariant = Color(0xFFBCCABB);
}
