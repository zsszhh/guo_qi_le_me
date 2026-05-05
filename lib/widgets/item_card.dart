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
        child: Stack(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: AppRadius.large,
                border: Border.all(
                  color: AppColors.outlineVariant.withOpacity(0.3),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
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
                        Text(
                          _buildSubtitle(),
                          style: AppTypography.bodySm.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
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
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(AppRadius.lg),
                  bottomRight: Radius.circular(AppRadius.lg),
                ),
                child: ExpiryProgressBar(
                  purchaseDate: purchaseDate,
                  expiryDate: expiryDate,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon() {
    // 根据分类名称返回图标
    if (category == PresetCategories.food) {
      return Icons.restaurant;
    } else if (category == PresetCategories.drug) {
      return Icons.medication;
    }
    // 其他分类返回默认图标
    return Icons.inventory_2;
  }

  String _buildSubtitle() {
    final parts = <String>[];
    if (location != null) {
      parts.add(location!);
    }
    final days = app_utils.DateUtils.daysRemaining(purchaseDate);
    if (days < 0) {
      parts.add('${-days}天前添加');
    } else if (days == 0) {
      parts.add('今天添加');
    } else {
      parts.add('$days天前添加');
    }
    return parts.join(' · ');
  }
}
