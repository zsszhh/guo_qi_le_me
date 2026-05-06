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
          // 使用 TweenAnimationBuilder 动画化整个进度区域
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: progress),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOutCubic,
            builder: (context, animatedProgress, child) {
              return _buildProgressSection(animatedProgress);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSection(double animatedProgress) {
    final progressColor = _getProgressColor(animatedProgress);
    final todayColor = daysRemaining < 0 ? AppColors.error : AppColors.primary;

    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            // 进度条区域
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
                        width: totalWidth * animatedProgress,
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
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                // 底部日期标记
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 购买日期
                    _buildDateMarker(
                      '购买',
                      _formatDate(purchaseDate),
                      AppColors.outlineVariant,
                    ),
                    // 过期日期
                    _buildDateMarker(
                      '过期',
                      _formatDate(expiryDate),
                      AppColors.outlineVariant,
                    ),
                  ],
                ),
              ],
            ),
            // 今天标记点 + 文字（根据动画进度定位）
            Positioned(
              left: totalWidth * animatedProgress - 8, // 减去圆点半径使其居中
              top: -2,
              child: Column(
                children: [
                  // 圆点
                  Container(
                    width: 16,
                    height: 16,
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
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  // 今天文字
                  Text(
                    '今天',
                    style: AppTypography.labelCaps.copyWith(
                      color: todayColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDateMarker(String label, String date, Color color) {
    return Column(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTypography.labelCaps.copyWith(
            color: AppColors.onSurfaceVariant,
            fontSize: 10,
          ),
        ),
        Text(
          date,
          style: AppTypography.labelCaps.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
      ],
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
