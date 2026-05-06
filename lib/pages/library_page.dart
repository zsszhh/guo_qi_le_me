import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/item.dart';
import '../providers/item_provider.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import '../theme/spacing.dart';
import '../utils/constants.dart';
import '../widgets/item_card.dart';
import 'item_edit_page.dart';
import 'item_detail_page.dart';

/// 物品库页面
class LibraryPage extends ConsumerStatefulWidget {
  const LibraryPage({super.key});

  @override
  ConsumerState<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends ConsumerState<LibraryPage> {
  bool _isSelectionMode = false;
  final Set<String> _selectedIds = {};

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(itemsProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text(
          '物品库',
          style: AppTypography.headlineMd.copyWith(
            color: AppColors.onSurface,
          ),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              _isSelectionMode ? Icons.close : Icons.checklist,
              color: AppColors.onSurface,
            ),
            onPressed: () {
              setState(() {
                _isSelectionMode = !_isSelectionMode;
                _selectedIds.clear();
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 筛选栏
          _buildFilterBar(context, state),

          // 物品列表
          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : state.filteredItems.isEmpty
                    ? _buildEmptyState(context)
                    : _buildItemsList(context, ref, state),
          ),
        ],
      ),
      // 批量操作栏
      bottomNavigationBar: _isSelectionMode && _selectedIds.isNotEmpty
          ? _buildBatchActionBar(context, ref)
          : null,
      // 添加按钮
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const ItemEditPage(),
            ),
          );
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  /// 构建筛选栏
  Widget _buildFilterBar(BuildContext context, ItemsState state) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        children: [
          // 搜索框
          TextField(
            onChanged: (value) {
              ref.read(itemsProvider.notifier).setSearchQuery(value);
            },
            decoration: InputDecoration(
              hintText: '搜索物品...',
              hintStyle: AppTypography.bodyBase.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
              prefixIcon: Icon(Icons.search, color: AppColors.onSurfaceVariant),
              filled: true,
              fillColor: AppColors.surfaceContainer,
              border: OutlineInputBorder(
                borderRadius: AppRadius.medium,
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          // 筛选按钮行
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip(
                  label: '分类',
                  value: state.filterCategory,
                  onTap: () => _showCategoryFilter(context),
                ),
                const SizedBox(width: AppSpacing.sm),
                _buildFilterChip(
                  label: '状态',
                  value: state.filterStatus?.displayName,
                  onTap: () => _showStatusFilter(context),
                ),
                const SizedBox(width: AppSpacing.sm),
                _buildFilterChip(
                  label: '位置',
                  value: state.filterLocation,
                  onTap: () => _showLocationFilter(context, state),
                ),
                const SizedBox(width: AppSpacing.sm),
                _buildSortChip(context, state),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 构建筛选按钮
  Widget _buildFilterChip({
    required String label,
    required String? value,
    required VoidCallback onTap,
  }) {
    final isActive = value != null;
    return FilterChip(
      label: Text(
        isActive ? '$label: $value' : label,
        style: AppTypography.bodySm.copyWith(
          color: isActive ? AppColors.onPrimary : AppColors.onSurface,
        ),
      ),
      selected: isActive,
      onSelected: (_) => onTap(),
      backgroundColor: AppColors.surfaceContainer,
      selectedColor: AppColors.primary,
      checkmarkColor: AppColors.onPrimary,
    );
  }

  /// 构建排序按钮
  Widget _buildSortChip(BuildContext context, ItemsState state) {
    String sortLabel;
    switch (state.sortType) {
      case SortType.expiryDate:
        sortLabel = '过期日期';
        break;
      case SortType.createdAt:
        sortLabel = '添加时间';
        break;
      case SortType.name:
        sortLabel = '名称';
        break;
    }

    return ActionChip(
      avatar: Icon(Icons.sort, size: 18, color: AppColors.onSurface),
      label: Text(
        sortLabel,
        style: AppTypography.bodySm.copyWith(color: AppColors.onSurface),
      ),
      onPressed: () => _showSortOptions(context, state),
      backgroundColor: AppColors.surfaceContainer,
    );
  }

  /// 构建空状态
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 64,
            color: AppColors.onSurfaceVariant.withOpacity(0.5),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            '没有找到物品',
            style: AppTypography.titleLg.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建物品列表
  Widget _buildItemsList(
    BuildContext context,
    WidgetRef ref,
    ItemsState state,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      itemCount: state.filteredItems.length,
      itemBuilder: (context, index) {
        final item = state.filteredItems[index];
        final isSelected = _selectedIds.contains(item.id);

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          child: _isSelectionMode
              ? _buildSelectableItemCard(item, isSelected)
              : ItemCard(
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
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => ItemDetailPage(itemId: item.id),
                      ),
                    );
                  },
                  onLongPress: () {
                    setState(() {
                      _isSelectionMode = true;
                      _selectedIds.add(item.id);
                    });
                  },
                ),
        );
      },
    );
  }

  /// 构建可选择物品卡片
  Widget _buildSelectableItemCard(Item item, bool isSelected) {
    return InkWell(
      onTap: () {
        setState(() {
          if (isSelected) {
            _selectedIds.remove(item.id);
          } else {
            _selectedIds.add(item.id);
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryContainer.withOpacity(0.3)
              : AppColors.surfaceContainerLowest,
          borderRadius: AppRadius.large,
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.outlineVariant.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.check_circle : Icons.circle_outlined,
              color: isSelected ? AppColors.primary : AppColors.onSurfaceVariant,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: AppTypography.bodyBase.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    item.category,
                    style: AppTypography.bodySm.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建批量操作栏
  Widget _buildBatchActionBar(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Text(
            '已选 ${_selectedIds.length} 项',
            style: AppTypography.bodyBase.copyWith(
              color: AppColors.onSurface,
            ),
          ),
          const Spacer(),
          TextButton.icon(
            onPressed: () => _deleteSelected(context, ref),
            icon: const Icon(Icons.delete, color: AppColors.error),
            label: Text(
              '删除',
              style: AppTypography.bodyBase.copyWith(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  /// 显示分类筛选
  void _showCategoryFilter(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('全部'),
              onTap: () {
                ref.read(itemsProvider.notifier).setCategoryFilter(null);
                Navigator.pop(context);
              },
            ),
            ...PresetCategories.defaults.map((category) => ListTile(
              title: Text(category),
              onTap: () {
                ref.read(itemsProvider.notifier).setCategoryFilter(category);
                Navigator.pop(context);
              },
            )),
          ],
        ),
      ),
    );
  }

  /// 显示状态筛选
  void _showStatusFilter(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('全部'),
              onTap: () {
                ref.read(itemsProvider.notifier).setStatusFilter(null);
                Navigator.pop(context);
              },
            ),
            ...ItemStatus.values.map((status) => ListTile(
                  title: Text(status.displayName),
                  onTap: () {
                    ref.read(itemsProvider.notifier).setStatusFilter(status);
                    Navigator.pop(context);
                  },
                )),
          ],
        ),
      ),
    );
  }

  /// 显示位置筛选
  void _showLocationFilter(BuildContext context, ItemsState state) {
    final locations = state.locations;
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('全部'),
              onTap: () {
                ref.read(itemsProvider.notifier).setLocationFilter(null);
                Navigator.pop(context);
              },
            ),
            ...locations.map((location) => ListTile(
                  title: Text(location),
                  onTap: () {
                    ref.read(itemsProvider.notifier).setLocationFilter(location);
                    Navigator.pop(context);
                  },
                )),
          ],
        ),
      ),
    );
  }

  /// 显示排序选项
  void _showSortOptions(BuildContext context, ItemsState state) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text('按过期日期'),
              trailing: state.sortType == SortType.expiryDate
                  ? const Icon(Icons.check, color: AppColors.primary)
                  : null,
              onTap: () {
                ref.read(itemsProvider.notifier).setSortType(SortType.expiryDate);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.schedule),
              title: const Text('按添加时间'),
              trailing: state.sortType == SortType.createdAt
                  ? const Icon(Icons.check, color: AppColors.primary)
                  : null,
              onTap: () {
                ref.read(itemsProvider.notifier).setSortType(SortType.createdAt);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.sort_by_alpha),
              title: const Text('按名称'),
              trailing: state.sortType == SortType.name
                  ? const Icon(Icons.check, color: AppColors.primary)
                  : null,
              onTap: () {
                ref.read(itemsProvider.notifier).setSortType(SortType.name);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  /// 删除选中项
  void _deleteSelected(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除选中的 ${_selectedIds.length} 个物品吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              ref.read(itemsProvider.notifier).deleteItems(_selectedIds.toList());
              Navigator.pop(context);
              setState(() {
                _isSelectionMode = false;
                _selectedIds.clear();
              });
            },
            child: const Text('删除', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}
