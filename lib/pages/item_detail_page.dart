import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/item.dart';
import '../providers/item_provider.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import '../theme/spacing.dart';
import '../utils/constants.dart';
import '../utils/date_utils.dart' as app_utils;
import '../widgets/hero_image_section.dart';
import '../widgets/lifecycle_timeline.dart';
import '../widgets/ai_analysis_card.dart';
import '../widgets/consume_bottom_sheet.dart';
import '../widgets/message_toast.dart';
import '../data/expiry_rules.dart';
import 'item_edit_page.dart';

/// 物品详情页
class ItemDetailPage extends ConsumerWidget {
  final String itemId;

  const ItemDetailPage({super.key, required this.itemId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemAsync = ref.watch(itemByIdProvider(itemId));

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text(
          '物品详情',
          style: AppTypography.headlineMd.copyWith(
            color: AppColors.onSurface,
          ),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) => _handleMenuAction(context, ref, value),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'delete',
                child: Text('删除'),
              ),
            ],
          ),
        ],
      ),
      body: itemAsync == null
          ? const Center(child: Text('物品不存在'))
          : _buildContent(context, ref, itemAsync),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, Item item) {
    final daysRemaining = app_utils.DateUtils.daysRemaining(item.expiryDate);

    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero大图区域
              HeroImageSection(item: item, daysRemaining: daysRemaining),

              // 标题区域
              _buildTitleSection(item),

              // 生命周期时间轴
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.containerMargin),
                child: LifecycleTimeline(
                  purchaseDate: item.purchaseDate,
                  expiryDate: item.expiryDate,
                  daysRemaining: daysRemaining,
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // 建议使用日期
              if (item.suggestedUseDate != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.containerMargin),
                  child: _buildSuggestedDateCard(item),
                ),

              // AI保质期分析
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.containerMargin),
                child: Consumer(
                  builder: (context, ref, _) {
                    final configAsync = ref.watch(defaultAIConfigProvider);
                    return configAsync.when(
                      data: (config) {
                        // 没有配置AI时不显示
                        if (config == null) return const SizedBox.shrink();
                        return AIAnalysisCard(item: item, aiConfig: config);
                      },
                      loading: () => const SizedBox.shrink(),
                      error: (error, stackTrace) => const SizedBox.shrink(),
                    );
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),

        // 底部操作栏
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: _buildBottomActionBar(context, ref, item),
        ),
      ],
    );
  }

  /// 构建标题区域
  Widget _buildTitleSection(Item item) {
    final statusText = item.openedDate != null ? '已开封' : '未开封';
    final parts = <String>[
      item.category,
      if (item.specification != null && item.specification!.isNotEmpty) item.specification!,
      statusText,
    ];

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.containerMargin),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.name,
            style: AppTypography.display.copyWith(
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          // 副标题：分类 · 规格 · 状态
          Text(
            parts.join(' · '),
            style: AppTypography.bodyBase.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          // 位置和数量信息
          Row(
            children: [
              if (item.location != null && item.location!.isNotEmpty) ...[
                Icon(
                  Icons.place_outlined,
                  size: 16,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 4),
                Text(
                  item.location!,
                  style: AppTypography.bodySm.copyWith(
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
              ],
              Icon(
                Icons.inventory_2_outlined,
                size: 16,
                color: AppColors.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Text(
                '${item.quantity}${item.unit}',
                style: AppTypography.bodySm.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 构建建议使用日期卡片
  Widget _buildSuggestedDateCard(Item item) {
    final suggestedDate = item.suggestedUseDate!;
    final days = suggestedDate.difference(DateTime.now()).inDays;
    final source = item.useDateSource ?? 'rule';

    Color bgColor;
    Color textColor;
    IconData icon;
    String statusText;

    if (days > 3) {
      bgColor = AppColors.primaryContainer;
      textColor = AppColors.onPrimaryContainer;
      icon = Icons.event_available_rounded;
      statusText = '建议使用日期';
    } else if (days > 0) {
      bgColor = Colors.orange.withValues(alpha: 0.15);
      textColor = Colors.orange;
      icon = Icons.warning_amber_rounded;
      statusText = '即将到期';
    } else {
      bgColor = Colors.red.withValues(alpha: 0.15);
      textColor = Colors.red;
      icon = Icons.error_outline;
      statusText = '已超过建议日期';
    }

    final rule = ExpiryRules.findRule(item.category, item.subCategory);
    final storageTip = rule?.storageTip;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: AppRadius.medium,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: textColor, size: 20),
              const SizedBox(width: 8),
              Text(
                statusText,
                style: AppTypography.bodyBase.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${suggestedDate.month}月${suggestedDate.day}日 前建议使用完毕',
            style: AppTypography.bodySm.copyWith(
              color: textColor,
            ),
          ),
          if (storageTip != null) ...[
            const SizedBox(height: 4),
            Text(
              '存储建议：$storageTip',
              style: AppTypography.bodySm.copyWith(
                color: textColor.withValues(alpha: 0.8),
              ),
            ),
          ],
          if (source == 'ai') ...[
            const SizedBox(height: 4),
            Text(
              '（AI 智能分析）',
              style: AppTypography.bodySm.copyWith(
                color: textColor.withValues(alpha: 0.6),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 构建底部操作栏
  Widget _buildBottomActionBar(BuildContext context, WidgetRef ref, Item item) {
    final isDisabled = item.status == ItemStatus.consumed || item.quantity <= 0;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.95),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // 编辑按钮
            _buildSquareButton(
              icon: Icons.edit_outlined,
              label: '编辑',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => ItemEditPage(itemId: item.id),
                  ),
                );
              },
            ),
            const SizedBox(width: AppSpacing.sm),
            // 删除按钮
            _buildSquareButton(
              icon: Icons.delete_outline,
              label: '删除',
              isDestructive: true,
              onPressed: () => _showDeleteConfirmDialog(context, ref),
            ),
            const SizedBox(width: AppSpacing.md),
            // 使用按钮（组合按钮：左边使用，右边下拉菜单）
            Expanded(
              child: _buildPrimaryButton(
                context: context,
                ref: ref,
                item: item,
                isDisabled: isDisabled,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建方形按钮（编辑/删除）
  Widget _buildSquareButton({
    required IconData icon,
    required String label,
    bool isDestructive = false,
    VoidCallback? onPressed,
  }) {
    final isEnabled = onPressed != null;
    return Container(
      width: 72,
      height: 48,
      decoration: BoxDecoration(
        color: isDestructive
            ? AppColors.errorContainer.withValues(alpha: 0.3)
            : AppColors.surfaceContainer,
        borderRadius: AppRadius.medium,
        border: Border.all(
          color: isDestructive
              ? AppColors.error.withValues(alpha: 0.3)
              : AppColors.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: InkWell(
        onTap: onPressed,
        borderRadius: AppRadius.medium,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20,
              color: isDestructive
                  ? (isEnabled ? AppColors.error : AppColors.onSurfaceVariant)
                  : (isEnabled ? AppColors.onSurface : AppColors.onSurfaceVariant),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: AppTypography.labelCaps.copyWith(
                fontSize: 10,
                color: isDestructive
                    ? (isEnabled ? AppColors.error : AppColors.onSurfaceVariant)
                    : (isEnabled ? AppColors.onSurface : AppColors.onSurfaceVariant),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建主要操作按钮（使用按钮）
  Widget _buildPrimaryButton({
    required BuildContext context,
    required WidgetRef ref,
    required Item item,
    required bool isDisabled,
  }) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: isDisabled ? AppColors.surfaceContainer : AppColors.primary,
        borderRadius: AppRadius.medium,
      ),
      child: Row(
        children: [
          // 左边：使用按钮
          Expanded(
            child: InkWell(
              onTap: isDisabled ? null : () => _consumeOne(context, ref, item),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppRadius.md),
                bottomLeft: Radius.circular(AppRadius.md),
              ),
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_circle,
                      size: 18,
                      color: isDisabled
                          ? AppColors.onSurfaceVariant
                          : AppColors.onPrimary,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      '使用',
                      style: AppTypography.bodyBase.copyWith(
                        color: isDisabled
                            ? AppColors.onSurfaceVariant
                            : AppColors.onPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // 分隔线
          Container(
            width: 1,
            height: 24,
            color: isDisabled
                ? AppColors.onSurfaceVariant.withValues(alpha: 0.3)
                : AppColors.onPrimary.withValues(alpha: 0.3),
          ),
          // 右边：下拉菜单按钮
          PopupMenuButton<String>(
            enabled: !isDisabled,
            onSelected: (value) => _handleConsumeAction(context, ref, item, value),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'consume_multiple',
                child: Row(
                  children: [
                    Icon(Icons.playlist_remove, size: 20),
                    SizedBox(width: AppSpacing.sm),
                    Text('使用多个'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'mark_consumed',
                child: Row(
                  children: [
                    Icon(Icons.check_circle_outline, size: 20),
                    SizedBox(width: AppSpacing.sm),
                    Text('标记已使用'),
                  ],
                ),
              ),
            ],
            offset: const Offset(0, -8),
            shape: RoundedRectangleBorder(
              borderRadius: AppRadius.medium,
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              height: 48,
              child: Icon(
                Icons.arrow_drop_up,
                color: isDisabled
                    ? AppColors.onSurfaceVariant
                    : AppColors.onPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 处理消耗操作
  void _handleConsumeAction(BuildContext context, WidgetRef ref, Item item, String action) {
    switch (action) {
      case 'consume_multiple':
        _showConsumeBottomSheet(context, ref, item);
        break;
      case 'mark_consumed':
        _showMarkConsumedDialog(context, ref);
        break;
    }
  }

  void _handleMenuAction(BuildContext context, WidgetRef ref, String action) {
    switch (action) {
      case 'delete':
        _showDeleteConfirmDialog(context, ref);
        break;
    }
  }

  /// 快速消耗 1 个
  void _consumeOne(BuildContext context, WidgetRef ref, Item item) {
    ref.read(itemsProvider.notifier).consumeItem(item.id, quantity: 1);

    final newQuantity = item.quantity - 1;

    if (newQuantity <= 0) {
      // 已消耗完毕，返回上一页
      Navigator.pop(context);
      MessageService.info(context, '已使用完毕');
    } else {
      // 显示剩余数量
      MessageService.success(context, '消耗成功，剩余 $newQuantity ${item.unit}');
    }
  }

  /// 显示消耗面板
  void _showConsumeBottomSheet(BuildContext context, WidgetRef ref, Item item) {
    ConsumeBottomSheet.show(
      context: context,
      item: item,
      onConfirm: (quantity) {
        ref.read(itemsProvider.notifier).consumeItem(item.id, quantity: quantity);

        final newQuantity = item.quantity - quantity;

        if (newQuantity <= 0) {
          // 已消耗完毕，返回上一页
          Navigator.pop(context);
          MessageService.info(context, '已使用完毕');
        } else {
          MessageService.success(context, '消耗成功，剩余 $newQuantity ${item.unit}');
        }
      },
    );
  }

  /// 显示标记已使用确认对话框
  void _showMarkConsumedDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认标记'),
        content: const Text('确定要将此物品标记为已使用吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(itemsProvider.notifier).markAsConsumed(itemId);
              Navigator.pop(context);
              Navigator.pop(context);
              MessageService.success(context, '已标记为使用完毕');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.onPrimary,
            ),
            child: const Text('确认'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('确定要删除这个物品吗？此操作无法撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              ref.read(itemsProvider.notifier).deleteItem(itemId);
              Navigator.pop(context); // 关闭对话框
              Navigator.pop(context); // 返回上一页
              MessageService.info(context, '物品已删除');
            },
            child: const Text('删除', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}
