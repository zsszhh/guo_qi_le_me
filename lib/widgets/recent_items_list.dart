import 'package:flutter/material.dart';
import '../models/item.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import '../theme/spacing.dart';
import '../utils/constants.dart';

/// 最近物品横向滚动列表
class RecentItemsList extends StatelessWidget {
  final List<Item> items;
  final void Function(Item item) onTap;

  const RecentItemsList({
    super.key,
    required this.items,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
          child: Text(
            '最近添加',
            style: AppTypography.labelCaps.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          height: 120,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.containerMargin),
            itemCount: items.length,
            separatorBuilder: (context, index) => const SizedBox(width: AppSpacing.md),
            itemBuilder: (context, index) {
              final item = items[index];
              return _RecentItemCard(item: item, onTap: () => onTap(item));
            },
          ),
        ),
      ],
    );
  }
}

class _RecentItemCard extends StatelessWidget {
  final Item item;
  final VoidCallback onTap;

  const _RecentItemCard({
    required this.item,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final daysRemaining = item.expiryDate.difference(DateTime.now()).inDays;
    final expiryDays = item.expiryDate.difference(item.purchaseDate).inDays;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 140,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.outlineVariant),
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
                  PresetCategories.getIcon(item.category),
                  size: 18,
                  color: AppColors.onSurfaceVariant,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  item.category,
                  style: AppTypography.bodySm.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              item.name,
              style: AppTypography.bodyBase.copyWith(
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: daysRemaining < 0
                    ? AppColors.errorContainer
                    : daysRemaining <= 7
                        ? AppColors.secondaryContainer
                        : AppColors.surfaceContainer,
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
              child: Text(
                '+ $expiryDays 天',
                style: AppTypography.labelCaps.copyWith(
                  fontSize: 10,
                  color: daysRemaining < 0
                      ? AppColors.onErrorContainer
                      : daysRemaining <= 7
                          ? AppColors.onSecondaryContainer
                          : AppColors.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
