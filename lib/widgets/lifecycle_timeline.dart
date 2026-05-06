import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import '../theme/spacing.dart';
import '../utils/constants.dart';

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
        border: Border.all(color: AppColors.surfaceVariant),
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
              Icon(
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
          const SizedBox(height: AppSpacing.xl),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: progress),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOutCubic,
            builder: (context, animatedProgress, child) {
              return _buildTimelineSection(animatedProgress);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineSection(double progress) {
    final progressColor = daysRemaining < 0
        ? AppColors.error
        : (daysRemaining <= AppConstants.urgentDaysThreshold ? AppColors.error : AppColors.primary);
    final todayColor = AppColors.error;

    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            // 进度条 + 端点文字
            Column(
              children: [
                // 进度条
                SizedBox(
                  height: 12,
                  child: Stack(
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
                      Container(
                        height: 12,
                        width: totalWidth * progress,
                        decoration: BoxDecoration(
                          color: progressColor,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(AppRadius.full),
                            bottomLeft: const Radius.circular(AppRadius.full),
                            topRight: Radius.circular(progress >= 1.0 ? AppRadius.full : 4),
                            bottomRight: Radius.circular(progress >= 1.0 ? AppRadius.full : 4),
                          ),
                        ),
                      ),
                      // 购买端竖线
                      Positioned(
                        left: 4,
                        top: 0,
                        child: Container(
                          width: 3,
                          height: 12,
                          decoration: BoxDecoration(
                            color: AppColors.outlineVariant,
                            borderRadius: BorderRadius.circular(1),
                          ),
                        ),
                      ),
                      // 过期端竖线
                      Positioned(
                        right: 4,
                        top: 0,
                        child: Container(
                          width: 3,
                          height: 12,
                          decoration: BoxDecoration(
                            color: AppColors.outlineVariant,
                            borderRadius: BorderRadius.circular(1),
                          ),
                        ),
                      ),
                      // 今天圆点 - 在进度条上
                      Positioned(
                        left: totalWidth * progress - 6,
                        top: 0,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: todayColor,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.surface,
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: todayColor.withValues(alpha: 0.3),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                // 端点文字行
                SizedBox(
                  height: 36,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildEndMarker(
                        label: '购买',
                        date: purchaseDate,
                      ),
                      _buildEndMarker(
                        label: '过期',
                        date: expiryDate,
                        isRight: true,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            // "今天"文字 - 在进度条上方，居中对齐圆点
            Positioned(
              left: totalWidth * progress - 24,
              bottom: 56, // 上移到进度条上方
              child: SizedBox(
                width: 48,
                child: Center(
                  child: Text(
                    '今天',
                    style: AppTypography.labelCaps.copyWith(
                      color: todayColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// 端点标记（购买/过期）
  Widget _buildEndMarker({
    required String label,
    required DateTime date,
    bool isRight = false,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: isRight ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.labelCaps.copyWith(
            color: AppColors.onSurfaceVariant,
            fontSize: 12,
          ),
        ),
        Text(
          '${date.month}/${date.day}',
          style: AppTypography.labelCaps.copyWith(
            color: AppColors.onSurfaceVariant,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
