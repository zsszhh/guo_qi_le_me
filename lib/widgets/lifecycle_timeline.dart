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
            // 进度条（背景）
            Container(
              height: 12,
              width: totalWidth,
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
            ),
            // 进度条（填充）
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
            // 购买日标记点（左端）
            Positioned(
              left: 0,
              top: -2,
              child: _buildMarker(
                '购买',
                _formatDate(purchaseDate),
                AppColors.outlineVariant,
                isToday: false,
              ),
            ),
            // 今天标记点（根据进度定位）
            Positioned(
              left: totalWidth * animatedProgress - 8,
              top: -2,
              child: _buildMarker(
                '今天',
                '',
                todayColor,
                isToday: true,
              ),
            ),
            // 过期日标记点（右端）
            Positioned(
              right: 0,
              top: -2,
              child: _buildMarker(
                '过期',
                _formatDate(expiryDate),
                AppColors.outlineVariant,
                isToday: false,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMarker(String label, String date, Color color, {required bool isToday}) {
    return Column(
      children: [
        // 圆点
        Container(
          width: isToday ? 16 : 8,
          height: isToday ? 16 : 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: isToday
                ? Border.all(
                    color: AppColors.surface,
                    width: 2,
                  )
                : null,
            boxShadow: isToday
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
        ),
        const SizedBox(height: 4),
        // 标签
        Text(
          label,
          style: AppTypography.labelCaps.copyWith(
            color: isToday ? color : AppColors.onSurfaceVariant,
            fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
            fontSize: 10,
          ),
        ),
        // 日期（今天不显示日期）
        if (!isToday && date.isNotEmpty)
          Text(
            date,
            style: AppTypography.labelCaps.copyWith(
              color: AppColors.onSurfaceVariant,
              fontSize: 10,
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
