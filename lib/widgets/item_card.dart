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
  final String category;          // 改为字符串支持自定义分类
  final String? subCategory;
  final DateTime purchaseDate;
  final DateTime expiryDate;
  final String? location;
  final String? imageUrl;
  final ItemStatus? status;       // 可选状态，优先使用此状态而非计算
  final int quantity;             // 数量
  final String unit;              // 单位
  final DateTime? openedDate;           // 开封日期
  final DateTime? suggestedUseDate;     // 建议使用日期
  final bool isIndividuallyWrapped;     // 是否独立包装
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onOpenTap;        // 快速开封回调

  const ItemCard({
    super.key,
    required this.name,
    required this.category,
    this.subCategory,
    required this.purchaseDate,
    required this.expiryDate,
    this.location,
    this.imageUrl,
    this.status,                   // 新增参数
    this.quantity = 1,
    this.unit = '个',
    this.openedDate,                    // 新增
    this.suggestedUseDate,              // 新增
    this.isIndividuallyWrapped = false, // 新增
    this.onTap,
    this.onLongPress,
    this.onOpenTap,                     // 新增
  });

  @override
  Widget build(BuildContext context) {
    // 优先使用传入的状态，否则根据过期日期计算
    final effectiveStatus = status ?? StatusUtils.calculateStatus(expiryDate);
    final daysRemaining = app_utils.DateUtils.daysRemaining(expiryDate);
    final categoryIcon = _getCategoryIcon();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: AppRadius.large,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: AppRadius.large,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha:0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: AppRadius.large,
            child: Stack(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLowest,
                    border: Border.all(
                      color: AppColors.outlineVariant.withValues(alpha:0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      // 图标/图片
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainer,
                          borderRadius: AppRadius.medium,
                        ),
                        child: Center(
                          child: Icon(
                            categoryIcon,
                            color: AppColors.primary,
                            size: 24,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      // 信息
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: AppTypography.bodyBase.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            _buildSubtitle(),
                          ],
                        ),
                      ),
                      // 状态徽章
                      StatusBadge(
                        status: effectiveStatus,
                        daysRemaining: daysRemaining,
                        compact: false,
                      ),
                    ],
                  ),
                ),
                // 底部进度条
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: ExpiryProgressBar(
                    purchaseDate: purchaseDate,
                    expiryDate: expiryDate,
                  ),
                ),
                // 建议日期提示或开封按钮
                if (_shouldShowSuggestedDate() || _shouldShowOpenButton())
                  Positioned(
                    bottom: 8,
                    right: AppSpacing.md,
                    child: _shouldShowSuggestedDate()
                        ? _buildSuggestedDateHint()
                        : _shouldShowOpenButton()
                            ? _buildOpenButton()
                            : const SizedBox.shrink(),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 计算距建议日期的天数
  int? _daysUntilSuggestedUse() {
    if (suggestedUseDate == null) return null;
    return suggestedUseDate!.difference(DateTime.now()).inDays;
  }

  /// 判断是否应该显示开封按钮
  bool _shouldShowOpenButton() {
    return openedDate == null && !isIndividuallyWrapped && onOpenTap != null;
  }

  /// 判断是否应该显示建议日期
  bool _shouldShowSuggestedDate() {
    return openedDate != null && suggestedUseDate != null;
  }

  IconData _getCategoryIcon() {
    return PresetCategories.getIcon(category);
  }

  Widget _buildSubtitle() {
    final parts = <Widget>[];
    final days = app_utils.DateUtils.daysRemaining(purchaseDate);
    final timeText = days < 0
        ? '${-days}天前添加'
        : days == 0
            ? '今天添加'
            : '$days天前添加';

    if (location != null && location!.isNotEmpty) {
      parts.add(Flexible(
        child: Text(
          location!,
          style: AppTypography.bodySm.copyWith(
            color: AppColors.primary,
            fontSize: 12,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ));
    }
    // 始终显示数量（只有1个也显示）
    if (parts.isNotEmpty) parts.add(_buildDot());
    parts.add(Text(
      '$quantity$unit',
      style: AppTypography.bodySm.copyWith(
        color: AppColors.onSurface,
        fontSize: 12,
      ),
    ));
    if (parts.isNotEmpty) parts.add(_buildDot());
    parts.add(Text(
      timeText,
      style: AppTypography.bodySm.copyWith(
        color: AppColors.onSurfaceVariant,
        fontSize: 12,
      ),
    ));

    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: parts,
    );
  }

  Widget _buildDot() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        '·',
        style: AppTypography.bodySm.copyWith(
          color: AppColors.onSurfaceVariant,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildSuggestedDateHint() {
    final days = _daysUntilSuggestedUse();
    if (days == null) return const SizedBox.shrink();

    String text;
    Color textColor;
    IconData? icon;

    if (days > 3) {
      text = '建议在 ${suggestedUseDate!.month}月${suggestedUseDate!.day}日 前用完';
      textColor = AppColors.onSurfaceVariant;
      icon = null;
    } else if (days > 0) {
      text = '建议在 ${suggestedUseDate!.month}月${suggestedUseDate!.day}日 前用完';
      textColor = Colors.orange;
      icon = Icons.warning_amber_rounded;
    } else {
      text = '已超过建议使用日期';
      textColor = Colors.red;
      icon = Icons.error_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: textColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: textColor),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: AppTypography.bodySm.copyWith(
              color: textColor,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOpenButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onOpenTap,
        borderRadius: AppRadius.small,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: AppRadius.small,
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.open_in_new_rounded,
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
      ),
    );
  }
}
