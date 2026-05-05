import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import '../theme/spacing.dart';
import '../providers/reminder_provider.dart';
import '../providers/item_provider.dart';
import '../models/item.dart';
import '../utils/constants.dart';
import '../utils/date_utils.dart' as app_utils;
import '../widgets/consume_bottom_sheet.dart';
import 'item_detail_page.dart';

/// 提醒中心页面
class ReminderCenterPage extends ConsumerWidget {
  const ReminderCenterPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(reminderProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text(
          '提醒中心',
          style: AppTypography.headlineMd.copyWith(
            color: AppColors.onSurface,
          ),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.tune),
            onPressed: () => ref.read(reminderProvider.notifier).loadReminders(),
          ),
        ],
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => ref.read(reminderProvider.notifier).loadReminders(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 周统计摘要卡片
                    _buildWeeklyOutlook(context, state),
                    const SizedBox(height: AppSpacing.lg),

                    // 待处理任务标题
                    _buildPendingTasksHeader(),
                    const SizedBox(height: AppSpacing.md),

                    // 任务列表
                    if (state.todayAttentionCount > 0)
                      ..._buildTaskList(context, ref, state)
                    else
                      _buildEmptyState(context),
                  ],
                ),
              ),
            ),
    );
  }

  /// 构建周统计摘要卡片
  Widget _buildWeeklyOutlook(BuildContext context, ReminderState state) {
    final expiringToday = state.urgentItems
        .where((item) => app_utils.DateUtils.daysRemaining(item.expiryDate) <= 0)
        .length;
    final next3Days = state.urgentItems
        .where((item) {
          final days = app_utils.DateUtils.daysRemaining(item.expiryDate);
          return days > 0 && days <= 3;
        })
        .length;
    final safeCount = state.expiringSoonItems.length;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(
          color: AppColors.surfaceContainerHighest,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题行
          Row(
            children: [
              Icon(
                Icons.analytics_outlined,
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                '本周概览',
                style: AppTypography.titleLg.copyWith(
                  color: AppColors.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainer,
                  borderRadius: AppRadius.small,
                ),
                child: Text(
                  '本周',
                  style: AppTypography.labelCaps.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // 三列统计
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  count: state.expiredItems.length,
                  label: '已过期',
                  backgroundColor: AppColors.errorContainer.withOpacity(0.4),
                  borderColor: AppColors.errorContainer.withOpacity(0.5),
                  textColor: AppColors.onErrorContainer,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _buildStatCard(
                  count: state.urgentItems.length,
                  label: '三天内',
                  backgroundColor: AppColors.secondaryContainer.withOpacity(0.4),
                  borderColor: AppColors.secondaryContainer.withOpacity(0.5),
                  textColor: AppColors.onSecondaryContainer,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _buildStatCard(
                  count: state.expiringSoonItems.length,
                  label: '七天内',
                  backgroundColor: AppColors.surfaceContainerHigh,
                  borderColor: AppColors.surfaceVariant,
                  textColor: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // 风险分布进度条
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '风险分布',
                style: AppTypography.labelCaps.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              Text(
                '共 ${state.todayAttentionCount} 件需关注',
                style: AppTypography.labelCaps.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          ClipRRect(
            borderRadius: AppRadius.small,
            child: SizedBox(
              height: 8,
              child: Row(
                children: [
                  if (state.expiredItems.isNotEmpty)
                    Expanded(
                      flex: state.expiredItems.length,
                      child: Container(color: AppColors.error),
                    ),
                  if (state.urgentItems.isNotEmpty)
                    Expanded(
                      flex: state.urgentItems.length,
                      child: Container(color: AppColors.secondary),
                    ),
                  if (state.expiringSoonItems.isNotEmpty)
                    Expanded(
                      flex: state.expiringSoonItems.length,
                      child: Container(color: AppColors.primary),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建统计卡片
  Widget _buildStatCard({
    required int count,
    required String label,
    required Color backgroundColor,
    required Color borderColor,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: AppRadius.medium,
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          Text(
            '$count',
            style: AppTypography.display.copyWith(
              color: textColor,
              fontSize: 28,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            label,
            style: AppTypography.labelCaps.copyWith(
              color: textColor,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// 构建待处理任务标题
  Widget _buildPendingTasksHeader() {
    return Row(
      children: [
        Icon(
          Icons.auto_awesome,
          color: AppColors.primary,
          size: 20,
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          '待处理任务',
          style: AppTypography.titleLg.copyWith(
            color: AppColors.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.primaryContainer.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.primaryContainer,
            ),
          ),
          child: Text(
            '智能排序',
            style: AppTypography.labelCaps.copyWith(
              color: AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }

  /// 构建任务列表
  List<Widget> _buildTaskList(
    BuildContext context,
    WidgetRef ref,
    ReminderState state,
  ) {
    final widgets = <Widget>[];

    // 已过期物品
    for (final item in state.expiredItems) {
      widgets.add(_buildTaskCard(context, ref, item, isExpired: true));
      widgets.add(const SizedBox(height: AppSpacing.sm));
    }

    // 急需处理物品
    for (final item in state.urgentItems) {
      widgets.add(_buildTaskCard(context, ref, item, isUrgent: true));
      widgets.add(const SizedBox(height: AppSpacing.sm));
    }

    // 即将过期物品
    for (final item in state.expiringSoonItems) {
      widgets.add(_buildTaskCard(context, ref, item));
      widgets.add(const SizedBox(height: AppSpacing.sm));
    }

    return widgets;
  }

  /// 构建任务卡片
  Widget _buildTaskCard(
    BuildContext context,
    WidgetRef ref,
    Item item, {
    bool isExpired = false,
    bool isUrgent = false,
  }) {
    final daysRemaining = app_utils.DateUtils.daysRemaining(item.expiryDate);
    final Color accentColor;
    final Color borderColor;

    if (isExpired) {
      accentColor = AppColors.error;
      borderColor = AppColors.error.withOpacity(0.2);
    } else if (isUrgent) {
      accentColor = AppColors.secondary;
      borderColor = AppColors.secondary.withOpacity(0.2);
    } else {
      accentColor = AppColors.primary;
      borderColor = AppColors.outlineVariant.withOpacity(0.3);
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: AppRadius.medium,
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // 左侧竖条
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: Container(
              width: 4,
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(AppRadius.md),
                  bottomLeft: Radius.circular(AppRadius.md),
                ),
              ),
            ),
          ),
          // 内容
          InkWell(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => ItemDetailPage(itemId: item.id),
                ),
              );
            },
            borderRadius: AppRadius.medium,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md).copyWith(left: AppSpacing.lg),
              child: Row(
                children: [
                  // 图片/图标
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainer,
                      borderRadius: AppRadius.medium,
                    ),
                    child: item.imageUrl != null
                        ? ClipRRect(
                            borderRadius: AppRadius.medium,
                            child: Image.network(
                              item.imageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _buildCategoryIcon(item),
                            ),
                          )
                        : _buildCategoryIcon(item),
                  ),
                  const SizedBox(width: AppSpacing.md),

                  // 信息
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: AppTypography.bodyBase.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _getStatusIcon(isExpired, isUrgent),
                              size: 14,
                              color: accentColor,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                _getStatusText(isExpired, isUrgent, daysRemaining),
                                style: AppTypography.labelCaps.copyWith(
                                  color: accentColor,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // 操作按钮
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 忽略按钮
                      _buildActionButton(
                        icon: Icons.close,
                        onPressed: () => _showDismissDialog(context, ref, item),
                        isPrimary: false,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      // 已使用按钮（带下拉）
                      _buildConsumeButton(context, ref, item),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建分类图标
  Widget _buildCategoryIcon(Item item) {
    return Icon(
      PresetCategories.getIcon(item.category),
      color: AppColors.onSurfaceVariant,
      size: 28,
    );
  }

  /// 获取状态图标
  IconData _getStatusIcon(bool isExpired, bool isUrgent) {
    if (isExpired) return Icons.error;
    if (isUrgent) return Icons.schedule;
    return Icons.check_circle_outline;
  }

  /// 获取状态文本
  String _getStatusText(bool isExpired, bool isUrgent, int daysRemaining) {
    if (isExpired) return '已过期';
    if (isUrgent) return '$daysRemaining 天后过期';
    return '$daysRemaining 天后过期';
  }

  /// 构建操作按钮
  Widget _buildActionButton({
    required IconData icon,
    String? label,
    required VoidCallback onPressed,
    required bool isPrimary,
  }) {
    if (label != null) {
      return ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: isPrimary ? AppColors.primary : AppColors.surfaceContainerHigh,
          foregroundColor: isPrimary ? AppColors.onPrimary : AppColors.onSurface,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.surfaceContainer,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 20,
          color: AppColors.onSurfaceVariant,
        ),
      ),
    );
  }

  /// 构建消耗按钮（带下拉箭头）
  Widget _buildConsumeButton(BuildContext context, WidgetRef ref, Item item) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 主按钮 - 快速消耗 1 个
          GestureDetector(
            onTap: () => _consumeOne(context, ref, item),
            child: Padding(
              padding: const EdgeInsets.only(left: AppSpacing.md),
              child: Row(
                children: [
                  Icon(
                    Icons.check,
                    size: 18,
                    color: AppColors.onPrimary,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    '已使用',
                    style: AppTypography.labelCaps.copyWith(
                      color: AppColors.onPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // 下拉箭头 - 显示消耗面板
          GestureDetector(
            onTap: () => _showConsumeBottomSheet(context, ref, item),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              child: Icon(
                Icons.arrow_drop_down,
                size: 20,
                color: AppColors.onPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 快速消耗 1 个
  void _consumeOne(BuildContext context, WidgetRef ref, Item item) {
    // 立即从 UI 中移除
    ref.read(reminderProvider.notifier).removeItem(item.id);

    // 异步更新数据库
    ref.read(itemsProvider.notifier).consumeItem(item.id, quantity: 1);

    final newQuantity = item.quantity - 1;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(newQuantity <= 0
            ? '已使用完毕'
            : '消耗成功，剩余 $newQuantity ${item.unit}'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// 显示消耗面板
  void _showConsumeBottomSheet(BuildContext context, WidgetRef ref, Item item) {
    ConsumeBottomSheet.show(
      context: context,
      item: item,
      onConfirm: (quantity) {
        // 从提醒列表移除
        ref.read(reminderProvider.notifier).removeItem(item.id);

        // 更新数据库
        ref.read(itemsProvider.notifier).consumeItem(item.id, quantity: quantity);

        final newQuantity = item.quantity - quantity;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(newQuantity <= 0
                ? '已使用完毕'
                : '消耗成功，剩余 $newQuantity ${item.unit}'),
            duration: const Duration(seconds: 2),
          ),
        );
      },
    );
  }

  /// 标记为已使用
  void _markAsConsumed(BuildContext context, WidgetRef ref, String itemId) {
    // 立即从 UI 中移除
    ref.read(reminderProvider.notifier).removeItem(itemId);

    // 异步更新数据库
    ref.read(itemsProvider.notifier).markAsConsumed(itemId);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('已标记为使用完毕'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  /// 显示忽略确认对话框
  void _showDismissDialog(BuildContext context, WidgetRef ref, Item item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('忽略提醒'),
        content: Text('确定要忽略「${item.name}」的提醒吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // 立即从 UI 中移除
              ref.read(reminderProvider.notifier).removeItem(item.id);
              // 异步更新数据库
              ref.read(itemsProvider.notifier).markAsConsumed(item.id);
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

  /// 构建空状态
  Widget _buildEmptyState(BuildContext context) {
    return SizedBox(
      width: double.infinity,  // 占满整行宽度
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 64,
              color: AppColors.primary.withOpacity(0.5),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              '暂无需要关注的物品',
              style: AppTypography.titleLg.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '所有物品状态正常',
              style: AppTypography.bodySm.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
