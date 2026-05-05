import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import '../theme/spacing.dart';
import '../utils/constants.dart';

/// 状态徽章组件
class StatusBadge extends StatelessWidget {
  final ItemStatus status;
  final int? daysRemaining;
  final bool compact;

  const StatusBadge({
    super.key,
    required this.status,
    this.daysRemaining,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final (backgroundColor, textColor, text) = _getBadgeStyle();

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? AppSpacing.sm : AppSpacing.md,
        vertical: compact ? AppSpacing.xs : AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: compact ? AppRadius.small : AppRadius.medium,
      ),
      child: compact
          ? Text(
              text,
              style: AppTypography.labelCaps.copyWith(
                color: textColor,
                fontSize: 10,
              ),
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _getNumberText(),
                  style: AppTypography.labelCaps.copyWith(
                    color: textColor,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _getLabelBelow(),
                  style: AppTypography.labelCaps.copyWith(
                    color: textColor,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
    );
  }

  /// 获取上方数字文本
  String _getNumberText() {
    final days = daysRemaining ?? 0;
    if (status == ItemStatus.consumed) {
      return '✓';
    }
    if (status == ItemStatus.expired) {
      // 已过期显示已过期的天数（取绝对值）
      return '${-days > 0 ? -days : 0}';
    }
    return '$days';
  }

  /// 获取下方标签文本
  String _getLabelBelow() {
    if (status == ItemStatus.consumed) {
      return '已使用';
    }
    if (status == ItemStatus.expired) {
      return '天前过期';
    }
    return '天后过期';
  }

  (Color, Color, String) _getBadgeStyle() {
    switch (status) {
      case ItemStatus.normal:
        return (
          AppColors.surfaceContainerHigh,
          AppColors.onSurface,
          '正常',
        );
      case ItemStatus.expiringSoon:
        return (
          AppColors.secondaryContainer,
          AppColors.onSecondaryContainer,
          '即将过期',
        );
      case ItemStatus.urgent:
        return (
          AppColors.errorContainer,
          AppColors.onErrorContainer,
          '急需处理',
        );
      case ItemStatus.expired:
        return (
          AppColors.errorContainer.withOpacity(0.5),
          AppColors.onErrorContainer,
          '已过期',
        );
      case ItemStatus.consumed:
        return (
          AppColors.primaryContainer.withOpacity(0.3),
          AppColors.primary,
          '已使用',
        );
    }
  }
}
