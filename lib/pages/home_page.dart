import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/item_provider.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import '../theme/spacing.dart';
import '../utils/constants.dart';
import '../widgets/item_card.dart';
import '../widgets/ai_button.dart';
import '../widgets/message_toast.dart';
import 'ai_input_page.dart';
import 'library_page.dart';
import 'item_detail_page.dart';

/// 首页
class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(itemsProvider);
    final stats = state.stats;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => ref.read(itemsProvider.notifier).loadItems(),
          child: CustomScrollView(
            slivers: [
              // 顶部标题
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.lg,
                    AppSpacing.lg,
                    AppSpacing.sm,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '过期了么',
                        style: AppTypography.display.copyWith(
                          color: AppColors.onSurface,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        '管理你的物品，不再过期',
                        style: AppTypography.bodyBase.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 搜索框
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.sm,
                  ),
                  child: TextField(
                    onChanged: (value) => ref.read(itemsProvider.notifier).setSearchQuery(value),
                    decoration: InputDecoration(
                      hintText: '搜索物品或分类...',
                      hintStyle: AppTypography.bodyBase.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                      prefixIcon: const Icon(Icons.search, color: AppColors.onSurfaceVariant),
                      filled: true,
                      fillColor: AppColors.surfaceContainerLowest,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(
                          color: AppColors.outlineVariant.withValues(alpha:0.3),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(
                          color: AppColors.outlineVariant.withValues(alpha:0.3),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: const BorderSide(color: AppColors.primary),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                    ),
                  ),
                ),
              ),

              // AI 智能录入按钮
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.sm,
                  ),
                  child: AIButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const AIInputPage(),
                        ),
                      );
                    },
                  ),
                ),
              ),

              // 状态统计卡片
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: _buildStatsCards(context, stats),
                ),
              ),

              // 快速访问标题
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '需要关注',
                        style: AppTypography.titleLg.copyWith(
                          color: AppColors.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const LibraryPage(),
                            ),
                          );
                        },
                        child: Text(
                          '查看全部',
                          style: AppTypography.bodySm.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 物品列表
              state.isLoading
                  ? const SliverToBoxAdapter(
                      child: Center(
                        child: Padding(
                          padding: EdgeInsets.all(AppSpacing.xl),
                          child: CircularProgressIndicator(),
                        ),
                      ),
                    )
                  : state.filteredItems.isEmpty
                      ? SliverToBoxAdapter(
                          child: _buildEmptyState(context),
                        )
                      : _buildItemsList(context, state),

              // 底部间距
              const SliverToBoxAdapter(
                child: SizedBox(height: AppSpacing.xl),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建状态统计卡片（Bento 布局）
  Widget _buildStatsCards(BuildContext context, ItemStats stats) {
    return Column(
      children: [
        // 第一行：正常 + 即将过期
        Row(
          children: [
            Expanded(
              child: _buildBentoCard(
                context,
                icon: Icons.check_circle,
                label: '正常',
                value: stats.normal,
                color: AppColors.primary,
                backgroundColor: AppColors.surfaceContainer,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _buildBentoCard(
                context,
                icon: Icons.warning,
                label: '即将过期',
                value: stats.expiringSoon,
                color: AppColors.onSecondaryContainer,
                backgroundColor: AppColors.secondaryContainer,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        // 第二行：急需处理 + 已过期
        Row(
          children: [
            Expanded(
              child: _buildBentoCard(
                context,
                icon: Icons.error,
                label: '急需处理',
                value: stats.urgent,
                color: AppColors.onErrorContainer,
                backgroundColor: AppColors.errorContainer,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _buildBentoCard(
                context,
                icon: Icons.cancel_outlined,
                label: '已过期',
                value: stats.expired,
                color: AppColors.onSurfaceVariant,
                backgroundColor: AppColors.surfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 构建单个 Bento 卡片
  Widget _buildBentoCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required int value,
    required Color color,
    required Color backgroundColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: AppRadius.large,
        border: Border.all(
          color: color.withValues(alpha:0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 图标
          Icon(icon, color: color, size: 24),
          const SizedBox(height: AppSpacing.sm),
          // 数值
          Text(
            value.toString(),
            style: AppTypography.display.copyWith(
              color: color,
              fontSize: 32,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          // 标签
          Text(
            label,
            style: AppTypography.bodySm.copyWith(
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建空状态
  Widget _buildEmptyState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 64,
            color: AppColors.onSurfaceVariant.withValues(alpha:0.5),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            '还没有物品',
            style: AppTypography.titleLg.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '点击上方按钮添加第一个物品吧',
            style: AppTypography.bodySm.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  /// 处理快速开封
  Future<void> _handleQuickOpen(String itemId) async {
    final aiConfig = await ref.read(defaultAIConfigProvider.future);
    await ref.read(itemsProvider.notifier).markAsOpened(itemId, aiConfig: aiConfig);

    if (mounted) {
      MessageService.success(context, '已标记为开封');
    }
  }

  /// 构建物品列表（按位置分组）
  Widget _buildItemsList(
    BuildContext context,
    ItemsState state,
  ) {
    // 只显示需要关注的物品（urgent 和 expiringSoon）
    final urgentItems = state.items
        .where((i) => i.status == ItemStatus.urgent || i.status == ItemStatus.expiringSoon)
        .toList();

    if (urgentItems.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Card(
            color: AppColors.primaryContainer.withValues(alpha:0.3),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      '太好了！没有需要紧急处理的物品',
                      style: AppTypography.bodyBase.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // 按位置分组
    final itemsByLocation = <String?, List<dynamic>>{};
    for (final item in urgentItems) {
      final location = item.location;
      itemsByLocation.putIfAbsent(location, () => []).add(item);
    }

    // 排序：有位置的在前，无位置的在后
    final sortedLocations = itemsByLocation.keys.toList()
      ..sort((a, b) {
        if (a == null) return 1;
        if (b == null) return -1;
        return a.compareTo(b);
      });

    final widgets = <Widget>[];
    for (final location in sortedLocations) {
      final items = itemsByLocation[location]!;

      // 位置标题
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            top: AppSpacing.sm,
            bottom: AppSpacing.sm,
          ),
          child: Row(
            children: [
              Icon(
                _getLocationIcon(location),
                size: 18,
                color: AppColors.primary,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                location ?? '未分类',
                style: AppTypography.labelCaps.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      );

      // 该位置的物品
      for (final item in items) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.xs,
            ),
            child: ItemCard(
              name: item.name,
              category: item.category,
              subCategory: item.subCategory,
              purchaseDate: item.purchaseDate,
              expiryDate: item.expiryDate,
              location: item.location,
              imageUrl: item.imageUrl,
              status: item.status,
              quantity: item.quantity,
              unit: item.unit,
              openedDate: item.openedDate,
              suggestedUseDate: item.suggestedUseDate,
              isIndividuallyWrapped: item.isIndividuallyWrapped,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => ItemDetailPage(itemId: item.id),
                  ),
                );
              },
              onOpenTap: () => _handleQuickOpen(item.id),
            ),
          ),
        );
      }
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) => widgets[index],
        childCount: widgets.length,
      ),
    );
  }

  /// 根据位置名称获取图标
  IconData _getLocationIcon(String? location) {
    if (location == null) return Icons.inventory_2_outlined;

    final locationLower = location.toLowerCase();
    if (locationLower.contains('冰箱') || locationLower.contains('冷藏')) {
      return Icons.kitchen;
    } else if (locationLower.contains('冷冻')) {
      return Icons.ac_unit;
    } else if (locationLower.contains('储藏') || locationLower.contains('柜')) {
      return Icons.shelves;
    } else if (locationLower.contains('药箱') || locationLower.contains('药品')) {
      return Icons.medication;
    } else if (locationLower.contains('厨房')) {
      return Icons.restaurant;
    } else {
      return Icons.place_outlined;
    }
  }
}
