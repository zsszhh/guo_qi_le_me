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
          _buildProgressBar(progress),
          const SizedBox(height: AppSpacing.lg),
          _buildMarkers(),
        ],
      ),
    );
  }

  Widget _buildProgressBar(double progress) {
    final progressColor = _getProgressColor(progress);

    return Stack(
      children: [
        // 背景轨道
        Container(
          height: 12,
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(AppRadius.full),
          ),
        ),
        // 进度填充
        FractionallySizedBox(
          widthFactor: progress,
          child: Container(
            height: 12,
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
        ),
      ],
    );
  }

  Color _getProgressColor(double progress) {
    if (progress >= 0.8) return AppColors.error;
    if (progress >= 0.5) return AppColors.secondary;
    return AppColors.primary;
  }

  Widget _buildMarkers() {
    return Stack(
      children: [
        // 购买日期
        Positioned(
          left: 0,
          child: _buildMarker(
            _formatDate(purchaseDate),
            '购买',
            AppColors.outlineVariant,
          ),
        ),
        // 今天
        Positioned(
          left: 0,
          right: 0,
          child: Center(
            child: _buildMarker(
              '今天',
              '',
              daysRemaining < 0 ? AppColors.error : AppColors.primary,
              isToday: true,
            ),
          ),
        ),
        // 过期日期
        Positioned(
          right: 0,
          child: _buildMarker(
            _formatDate(expiryDate),
            '过期',
            AppColors.outlineVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildMarker(String text, String label, Color color, {bool isToday = false}) {
    return Column(
      children: [
        Container(
          width: isToday ? 12 : 4,
          height: isToday ? 12 : 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        if (label.isNotEmpty)
          Text(
            label,
            style: AppTypography.labelCaps.copyWith(
              color: AppColors.onSurfaceVariant,
              fontSize: 10,
            ),
          ),
        Text(
          text,
          style: AppTypography.labelCaps.copyWith(
            color: isToday ? color : AppColors.onSurfaceVariant,
            fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}';
  }
}
