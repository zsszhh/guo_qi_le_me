import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import '../theme/spacing.dart';

/// 生命周期时间轴
class LifecycleTimeline extends StatefulWidget {
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
  State<LifecycleTimeline> createState() => _LifecycleTimelineState();
}

class _LifecycleTimelineState extends State<LifecycleTimeline>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    // 延迟启动动画，确保用户能看到
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          _controller.forward();
        }
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final totalDays = widget.expiryDate.difference(widget.purchaseDate).inDays;
    final elapsedDays = DateTime.now().difference(widget.purchaseDate).inDays;
    final targetProgress = totalDays > 0 ? (elapsedDays / totalDays).clamp(0.0, 1.0) : 1.0;

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
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              final progress = _animation.value * targetProgress;
              return _buildProgressSection(progress);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSection(double progress) {
    final progressColor = _getProgressColor(progress);
    final todayColor = widget.daysRemaining < 0 ? AppColors.error : AppColors.primary;

    return Column(
      children: [
        // 进度条容器
        SizedBox(
          height: 12,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.full),
            child: Stack(
              children: [
                // 背景轨道
                Container(
                  height: 12,
                  width: double.infinity,
                  color: AppColors.surfaceVariant,
                ),
                // 进度填充
                FractionallySizedBox(
                  widthFactor: progress > 0 ? progress : 0,
                  child: Container(
                    height: 12,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary,
                          progressColor,
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        // 标记点行
        Row(
          children: [
            // 购买日
            Expanded(
              child: _buildMarker(
                '购买',
                _formatDate(widget.purchaseDate),
                AppColors.outlineVariant,
              ),
            ),
            // 今天 - 使用 Spacer 来定位
            Expanded(
              flex: (progress * 1000).toInt().clamp(1, 999),
              child: const SizedBox(),
            ),
            _buildMarker(
              '今天',
              '',
              todayColor,
              isToday: true,
            ),
            Expanded(
              flex: ((1 - progress) * 1000).toInt().clamp(1, 999),
              child: const SizedBox(),
            ),
            // 过期日
            Expanded(
              child: _buildMarker(
                '过期',
                _formatDate(widget.expiryDate),
                AppColors.outlineVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMarker(String label, String date, Color color, {bool isToday = false}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 圆点
        Container(
          width: isToday ? 12 : 6,
          height: isToday ? 12 : 6,
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
                      color: color.withValues(alpha: 0.4),
                      blurRadius: 4,
                      spreadRadius: 1,
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
        // 日期（今天不显示）
        if (!isToday)
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
