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
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

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
    this.onTap,
    this.onLongPress,
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
                color: Colors.black.withOpacity(0.04),
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
                      color: AppColors.outlineVariant.withOpacity(0.3),
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
              ],
            ),
          ),
        ),
      ),
    );
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

    if (location != null) {
      parts.add(Text(
        location!,
        style: AppTypography.bodySm.copyWith(
          color: AppColors.primary,
          fontSize: 12,
        ),
      ));
    }
    if (quantity > 1) {
      if (parts.isNotEmpty) parts.add(_buildDot());
      parts.add(Text(
        '$quantity个',
        style: AppTypography.bodySm.copyWith(
          color: AppColors.onSurface,
          fontSize: 12,
        ),
      ));
    }
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
}
