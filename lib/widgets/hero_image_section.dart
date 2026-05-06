import 'package:flutter/material.dart';
import '../models/item.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../utils/constants.dart';

/// Hero大图区域
class HeroImageSection extends StatelessWidget {
  final Item item;
  final int daysRemaining;

  const HeroImageSection({
    super.key,
    required this.item,
    required this.daysRemaining,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 512),
      child: AspectRatio(
        aspectRatio: 1.0,
        child: Container(
          margin: const EdgeInsets.all(AppSpacing.containerMargin),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border: Border.all(
              color: AppColors.outlineVariant.withValues(alpha: 0.3),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              // 图片或图标
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.xl),
                child: item.imageUrl != null
                    ? Image.network(
                        item.imageUrl!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                        errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
                      )
                    : _buildPlaceholder(),
              ),
              // 状态徽章
              Positioned(
                top: AppSpacing.md,
                left: AppSpacing.md,
                child: _buildStatusBadge(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: AppColors.surfaceVariant,
      child: Center(
        child: Icon(
          PresetCategories.getIcon(item.category),
          size: 64,
          color: AppColors.primary.withValues(alpha: 0.5),
        ),
      ),
    );
  }

  Widget _buildStatusBadge() {
    String text;
    Color bgColor;
    Color textColor;
    IconData icon;

    if (daysRemaining < 0) {
      text = '已过期 ${-daysRemaining} 天';
      bgColor = AppColors.errorContainer;
      textColor = AppColors.onErrorContainer;
      icon = Icons.warning;
    } else if (daysRemaining <= AppConstants.urgentDaysThreshold) {
      text = '还有 $daysRemaining 天过期';
      bgColor = AppColors.errorContainer;
      textColor = AppColors.onErrorContainer;
      icon = Icons.warning;
    } else if (daysRemaining <= AppConstants.warningDaysThreshold) {
      text = '还有 $daysRemaining 天过期';
      bgColor = AppColors.secondaryContainer;
      textColor = AppColors.onSecondaryContainer;
      icon = Icons.schedule;
    } else {
      text = '正常';
      bgColor = AppColors.primaryContainer;
      textColor = AppColors.onPrimaryContainer;
      icon = Icons.check_circle;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppRadius.full),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 4,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: textColor),
          const SizedBox(width: AppSpacing.xs),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.05,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
