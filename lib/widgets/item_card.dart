import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import '../theme/spacing.dart';
import '../utils/constants.dart';
import '../utils/status_utils.dart';
import '../utils/date_utils.dart' as app_utils;
import 'status_badge.dart';
import 'expiry_progress_bar.dart';

/// 物品卡片组件
class ItemCard extends StatelessWidget {
  final String name;
  final String category;
  final String? subCategory;
  final DateTime purchaseDate;
  final DateTime expiryDate;
  final String? location;
  final String? imageUrl;
  final ItemStatus? status;
  final int quantity;
  final String unit;
  final DateTime? openedDate;
  final DateTime? suggestedUseDate;
  final bool isIndividuallyWrapped;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onOpenTap;

  const ItemCard({
    super.key,
    required this.name,
    required this.category,
    this.subCategory,
    required this.purchaseDate,
    required this.expiryDate,
    this.location,
    this.imageUrl,
    this.status,
    this.quantity = 1,
    this.unit = '个',
    this.openedDate,
    this.suggestedUseDate,
    this.isIndividuallyWrapped = false,
    this.onTap,
    this.onLongPress,
    this.onOpenTap,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveStatus = status ?? StatusUtils.calculateStatus(expiryDate);
    final daysRemaining = app_utils.DateUtils.daysRemaining(expiryDate);
    final categoryIcon = PresetCategories.getIcon(category);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: AppRadius.large,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: AppRadius.large,
            color: AppColors.surfaceContainerLowest,
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
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 主要内容区域
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      AppSpacing.md,
                      AppSpacing.md,
                      AppSpacing.sm,
                    ),
                    child: Row(
                      children: [
                        // 左侧图标
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainer,
                            borderRadius: AppRadius.medium,
                          ),
                          child: Icon(
                            categoryIcon,
                            color: AppColors.primary,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        // 中间信息
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 名称
                              Text(
                                name,
                                style: AppTypography.bodyBase.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              // 副标题
                              _buildSubtitle(),
                            ],
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        // 右侧状态徽章
                        StatusBadge(
                          status: effectiveStatus,
                          daysRemaining: daysRemaining,
                        ),
                      ],
                    ),
                  ),
                  // 建议日期提示（已开封物品）
                  if (_shouldShowSuggestedDate())
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: 4,
                      ),
                      child: _buildSuggestedDateHint(),
                    ),
                  // 底部进度条
                  ExpiryProgressBar(
                    purchaseDate: purchaseDate,
                    expiryDate: expiryDate,
                  ),
                ],
              ),
              // 右上角开封按钮
              if (_shouldShowOpenButton())
                Positioned(
                  top: 8,
                  right: 8,
                  child: _buildOpenButton(),
                ),
            ],
          ),
        ),
      ),
    );
  }

  bool _shouldShowOpenButton() {
    return openedDate == null && !isIndividuallyWrapped && onOpenTap != null;
  }

  bool _shouldShowSuggestedDate() {
    return openedDate != null && suggestedUseDate != null;
  }

  int? _daysUntilSuggestedUse() {
    if (suggestedUseDate == null) return null;
    return suggestedUseDate!.difference(DateTime.now()).inDays;
  }

  Widget _buildSubtitle() {
    final days = app_utils.DateUtils.daysRemaining(purchaseDate);
    final timeText = days < 0
        ? '${-days}天前'
        : days == 0
            ? '今天'
            : '$days天前';

    final parts = <String>[];
    if (location != null && location!.isNotEmpty) {
      parts.add(location!);
    }
    parts.add('$quantity$unit');
    parts.add(timeText);

    return Text(
      parts.join(' · '),
      style: AppTypography.bodySm.copyWith(
        color: AppColors.onSurfaceVariant,
        fontSize: 12,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  /// 右上角开封按钮
  Widget _buildOpenButton() {
    return GestureDetector(
      onTap: onOpenTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: AppRadius.small,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.unarchive_rounded,
              size: 14,
              color: AppColors.primary,
            ),
            const SizedBox(width: 4),
            Text(
              '开封',
              style: AppTypography.bodySm.copyWith(
                color: AppColors.primary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestedDateHint() {
    final days = _daysUntilSuggestedUse();
    if (days == null) return const SizedBox.shrink();

    String text;
    Color bgColor;
    Color textColor;

    if (days > 3) {
      text = '建议 ${suggestedUseDate!.month}/${suggestedUseDate!.day} 前用完';
      bgColor = AppColors.surfaceContainer;
      textColor = AppColors.onSurfaceVariant;
    } else if (days > 0) {
      text = '⚠️ 建议尽快用完（剩$days天）';
      bgColor = Colors.orange.withValues(alpha: 0.15);
      textColor = Colors.orange.shade800;
    } else {
      text = '❗ 已超过建议使用日期';
      bgColor = Colors.red.withValues(alpha: 0.12);
      textColor = Colors.red.shade700;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: AppRadius.small,
      ),
      child: Text(
        text,
        style: AppTypography.bodySm.copyWith(
          color: textColor,
          fontSize: 12,
        ),
      ),
    );
  }
}
