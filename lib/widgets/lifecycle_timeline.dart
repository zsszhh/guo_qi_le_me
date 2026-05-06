import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import '../theme/spacing.dart';

/// 生命周期时间轴
class LifecycleTimeline extends StatelessWidget {
  final DateTime purchaseDate;
  final DateTime expiryDate;
  final int daysRemaining;

  const LifecycleTimeline({
    super.key,
    required this.purchaseDate,
    required this.expiryDate,
    required this.daysRemaining,
  });

  @override
  Widget build(BuildContext context) {
    final totalDays = expiryDate.difference(purchaseDate).inDays;
    final elapsedDays = DateTime.now().difference(purchaseDate).inDays;
    final progress = totalDays > 0 ? (elapsedDays / totalDays).clamp(0.0, 1.0) : 1.0;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.timeline,
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                '生命周期',
                style: AppTypography.titleLg.copyWith(
                  color: AppColors.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          _buildProgressSection(progress),
        ],
      ),
    );
  }

  Widget _buildProgressSection(double progress) {
    final progressColor = _getProgressColor(progress);
    final todayColor = daysRemaining < 0 ? AppColors.error : AppColors.primary;

    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        final progressWidth = totalWidth * progress;

        return Column(
          children: [
            // 进度条 + 今天标记点
            SizedBox(
              height: 24,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // 背景轨道
                  Container(
                    height: 12,
                    width: totalWidth,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(AppRadius.full),
                    ),
                  ),
                  // 进度填充
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: 12,
                    width: progressWidth,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary,
                          progressColor,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(AppRadius.full),
                    ),
                  ),
                  // 今天标记点（在进度条上方）
                  Positioned(
                    left: progressWidth - 6, // 圆点半径6，使其居中对齐进度终点
                    top: -2,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: todayColor,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.surface,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            // 日期标记行
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // 购买日期
                Column(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: AppColors.outlineVariant,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '购买',
                      style: AppTypography.labelCaps.copyWith(
                        color: AppColors.onSurfaceVariant,
                        fontSize: 10,
                      ),
                    ),
                    Text(
                      _formatDate(purchaseDate),
                      style: AppTypography.labelCaps.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                // 今天
                Column(
                  children: [
                    const SizedBox(height: 8), // 占位，因为圆点在进度条上
                    Text(
                      '今天',
                      style: AppTypography.labelCaps.copyWith(
                        color: todayColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                // 过期日期
                Column(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: AppColors.outlineVariant,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '过期',
                      style: AppTypography.labelCaps.copyWith(
                        color: AppColors.onSurfaceVariant,
                        fontSize: 10,
                      ),
                    ),
                    Text(
                      _formatDate(expiryDate),
                      style: AppTypography.labelCaps.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Color _getProgressColor(double progress) {
    if (progress >= 0.8) return AppColors.error;
    if (progress >= 0.5) return AppColors.secondary;
    return AppColors.primary;
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}';
  }
}
