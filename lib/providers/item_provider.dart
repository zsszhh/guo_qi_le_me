import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../data/expiry_rules.dart';
import '../models/ai_config.dart';
import '../models/item.dart';
import '../services/ai_service.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';
import '../utils/status_utils.dart';
import '../utils/constants.dart';

/// 物品状态类
class ItemsState {
  final List<Item> items;
  final bool isLoading;
  final String? error;
  final String searchQuery;
  final String? filterCategory;    // 改为字符串支持自定义分类
  final ItemStatus? filterStatus;
  final String? filterLocation;
  final SortType sortType;

  const ItemsState({
    this.items = const [],
    this.isLoading = false,
    this.error,
    this.searchQuery = '',
    this.filterCategory,
    this.filterStatus,
    this.filterLocation,
    this.sortType = SortType.expiryDate,
  });

  /// 获取过滤后的物品列表
  List<Item> get filteredItems {
    // 创建可变副本
    var result = List<Item>.from(items);

    // 搜索过滤
    if (searchQuery.isNotEmpty) {
      result = result.where((item) {
        final query = searchQuery.toLowerCase();
        return item.name.toLowerCase().contains(query) ||
            (item.brand?.toLowerCase().contains(query) ?? false) ||
            (item.location?.toLowerCase().contains(query) ?? false);
      }).toList();
    }

    // 分类过滤
    if (filterCategory != null) {
      result = result.where((item) => item.category == filterCategory).toList();
    }

    // 状态过滤
    if (filterStatus != null) {
      result = result.where((item) => item.status == filterStatus).toList();
    }

    // 位置过滤
    if (filterLocation != null) {
      result = result.where((item) => item.location == filterLocation).toList();
    }

    // 排序
    switch (sortType) {
      case SortType.expiryDate:
        result.sort((a, b) => a.expiryDate.compareTo(b.expiryDate));
        break;
      case SortType.createdAt:
        result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case SortType.name:
        result.sort((a, b) => a.name.compareTo(b.name));
        break;
    }

    return result;
  }

  /// 按状态分组
  Map<ItemStatus, List<Item>> get itemsByStatus {
    final filtered = filteredItems;
    return {
      ItemStatus.urgent: filtered.where((i) => i.status == ItemStatus.urgent).toList(),
      ItemStatus.expiringSoon: filtered.where((i) => i.status == ItemStatus.expiringSoon).toList(),
      ItemStatus.normal: filtered.where((i) => i.status == ItemStatus.normal).toList(),
      ItemStatus.expired: filtered.where((i) => i.status == ItemStatus.expired).toList(),
    };
  }

  /// 统计数据
  ItemStats get stats {
    return ItemStats.fromItems(items);
  }

  /// 获取所有位置
  List<String> get locations {
    final locationSet = <String>{};
    for (final item in items) {
      if (item.location != null && item.location!.isNotEmpty) {
        locationSet.add(item.location!);
      }
    }
    return locationSet.toList()..sort();
  }

  ItemsState copyWith({
    List<Item>? items,
    bool? isLoading,
    String? error,
    String? searchQuery,
    String? filterCategory,
    ItemStatus? filterStatus,
    String? filterLocation,
    SortType? sortType,
    bool clearError = false,
    bool clearCategoryFilter = false,
    bool clearStatusFilter = false,
    bool clearLocationFilter = false,
  }) {
    return ItemsState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      searchQuery: searchQuery ?? this.searchQuery,
      filterCategory: clearCategoryFilter ? null : (filterCategory ?? this.filterCategory),
      filterStatus: clearStatusFilter ? null : (filterStatus ?? this.filterStatus),
      filterLocation: clearLocationFilter ? null : (filterLocation ?? this.filterLocation),
      sortType: sortType ?? this.sortType,
    );
  }
}

/// 排序类型
enum SortType {
  expiryDate,
  createdAt,
  name,
}

/// 物品统计
class ItemStats {
  final int total;
  final int normal;
  final int expiringSoon;
  final int urgent;
  final int expired;
  final int consumed;

  const ItemStats({
    this.total = 0,
    this.normal = 0,
    this.expiringSoon = 0,
    this.urgent = 0,
    this.expired = 0,
    this.consumed = 0,
  });

  factory ItemStats.fromItems(List<Item> items) {
    return ItemStats(
      total: items.length,
      normal: items.where((i) => i.status == ItemStatus.normal).length,
      expiringSoon: items.where((i) => i.status == ItemStatus.expiringSoon).length,
      urgent: items.where((i) => i.status == ItemStatus.urgent).length,
      expired: items.where((i) => i.status == ItemStatus.expired).length,
      consumed: items.where((i) => i.status == ItemStatus.consumed).length,
    );
  }
}

/// 物品状态管理器
class ItemsNotifier extends StateNotifier<ItemsState> {
  final DatabaseService _dbService;

  ItemsNotifier(this._dbService) : super(const ItemsState()) {
    loadItems();
  }

  /// 加载所有物品
  Future<void> loadItems() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final items = await _dbService.getAllItems();
      // 更新状态（可能需要根据过期日期更新，但跳过 consumed 状态）
      final updatedItems = await _updateItemStatuses(items);
      state = state.copyWith(items: updatedItems, isLoading: false);

      // 更新应用角标
      NotificationService().updateBadge();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// 添加物品
  Future<void> addItem(Item item) async {
    try {
      // 计算状态
      final status = StatusUtils.calculateStatus(item.expiryDate);
      final itemWithStatus = item.copyWith(status: status);

      await _dbService.insertItem(itemWithStatus);
      await loadItems();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// 更新物品
  Future<void> updateItem(Item item) async {
    try {
      // 重新计算状态（但如果已经是 consumed，保持不变）
      ItemStatus status;
      if (item.status == ItemStatus.consumed) {
        status = ItemStatus.consumed;
      } else {
        status = StatusUtils.calculateStatus(item.expiryDate);
      }

      final updatedItem = item.copyWith(
        status: status,
        updatedAt: DateTime.now(),
      );

      await _dbService.updateItem(updatedItem);
      await loadItems();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// 删除物品
  Future<void> deleteItem(String id) async {
    try {
      await _dbService.deleteItem(id);
      await loadItems();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// 批量删除物品
  Future<void> deleteItems(List<String> ids) async {
    try {
      await _dbService.deleteItems(ids);
      await loadItems();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// 标记物品为已使用
  Future<void> markAsConsumed(String id) async {
    try {
      final item = state.items.where((i) => i.id == id).firstOrNull;
      if (item == null) return;

      final updatedItem = item.copyWith(
        status: ItemStatus.consumed,
        updatedAt: DateTime.now(),
      );

      await _dbService.updateItem(updatedItem);
      await loadItems();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// 快速开封物品
  /// 自动根据规则库或 AI 计算建议使用日期
  Future<void> markAsOpened(String id, {AIConfig? aiConfig}) async {
    try {
      final item = state.items.where((i) => i.id == id).firstOrNull;
      if (item == null) return;

      // 独立包装物品不生成建议日期
      if (item.isIndividuallyWrapped) {
        final updatedItem = item.copyWith(
          openedDate: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await _dbService.updateItem(updatedItem);
        await loadItems();
        return;
      }

      final now = DateTime.now();
      DateTime? suggestedUseDate;
      String? useDateSource;

      // 尝试从规则库获取
      final rule = ExpiryRules.findRule(item.category, item.subCategory);
      if (rule != null) {
        final days = rule.daysAfterOpened;
        suggestedUseDate = now.add(Duration(days: days));
        useDateSource = 'rule';
      } else if (aiConfig != null) {
        // 规则库无匹配，调用 AI 分析
        try {
          final aiService = AIService();
          final analysis = await aiService.analyzeOpenedExpiry(
            config: aiConfig,
            name: item.name,
            category: item.category,
            subCategory: item.subCategory,
            brand: item.brand,
            specification: item.specification,
            location: item.location,
          );

          suggestedUseDate = now.add(Duration(days: analysis.suggestedDays));
          useDateSource = 'ai';
        } catch (e) {
          // AI 调用失败，使用默认值
          suggestedUseDate = now.add(const Duration(days: ExpiryRules.defaultDaysAfterOpened));
          useDateSource = 'fallback';
        }
      } else {
        // 无 AI 配置，使用默认值
        suggestedUseDate = now.add(const Duration(days: ExpiryRules.defaultDaysAfterOpened));
        useDateSource = 'fallback';
      }

      // 确保建议日期不超过过期日期
      if (suggestedUseDate.isAfter(item.expiryDate)) {
        suggestedUseDate = item.expiryDate;
      }

      final updatedItem = item.copyWith(
        openedDate: now,
        suggestedUseDate: suggestedUseDate,
        useDateSource: useDateSource,
        updatedAt: now,
      );

      await _dbService.updateItem(updatedItem);
      await loadItems();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// 消耗物品（支持部分消耗）
  /// quantity: 消耗数量，默认为 1
  Future<void> consumeItem(String id, {int quantity = 1}) async {
    try {
      final item = state.items.where((i) => i.id == id).firstOrNull;
      if (item == null) return;

      final newQuantity = item.quantity - quantity;

      if (newQuantity <= 0) {
        // 数量归零，标记为已消耗
        await markAsConsumed(id);
      } else {
        // 更新剩余数量
        await _dbService.updateItemQuantity(id, newQuantity);
        await loadItems();
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// 批量标记物品为已使用
  Future<void> markItemsAsConsumed(List<String> ids) async {
    try {
      await _dbService.updateItemsStatus(ids, ItemStatus.consumed.name);
      await loadItems();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// 搜索物品
  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  /// 设置分类过滤
  void setCategoryFilter(String? category) {
    state = state.copyWith(
      filterCategory: category,
      clearCategoryFilter: category == null,
    );
  }

  /// 设置状态过滤
  void setStatusFilter(ItemStatus? status) {
    state = state.copyWith(
      filterStatus: status,
      clearStatusFilter: status == null,
    );
  }

  /// 设置位置过滤
  void setLocationFilter(String? location) {
    state = state.copyWith(
      filterLocation: location,
      clearLocationFilter: location == null,
    );
  }

  /// 设置排序方式
  void setSortType(SortType sortType) {
    state = state.copyWith(sortType: sortType);
  }

  /// 清除所有过滤
  void clearFilters() {
    state = state.copyWith(
      searchQuery: '',
      clearCategoryFilter: true,
      clearStatusFilter: true,
      clearLocationFilter: true,
    );
  }

  /// 更新物品状态（跳过 consumed 状态的物品，使用批量更新优化）
  Future<List<Item>> _updateItemStatuses(List<Item> items) async {
    // 按新状态分组
    final statusGroups = <String, List<String>>{}; // status -> list of ids
    final needsUpdate = <Item>[];

    for (final item in items) {
      // 跳过已使用的物品，保持其状态不变
      if (item.status == ItemStatus.consumed) {
        continue;
      }

      final correctStatus = StatusUtils.calculateStatus(item.expiryDate);
      if (item.status != correctStatus) {
        final statusName = correctStatus.name;
        statusGroups.putIfAbsent(statusName, () => []).add(item.id);
        needsUpdate.add(item);
      }
    }

    // 批量更新状态（按状态分组更新）
    for (final entry in statusGroups.entries) {
      await _dbService.updateItemsStatus(entry.value, entry.key);
    }

    // 如果有更新，返回新列表
    if (needsUpdate.isNotEmpty) {
      return items.map((item) {
        if (item.status == ItemStatus.consumed) {
          return item;
        }

        final correctStatus = StatusUtils.calculateStatus(item.expiryDate);
        if (item.status != correctStatus) {
          return item.copyWith(status: correctStatus);
        }
        return item;
      }).toList();
    }

    return items;
  }

  /// 搜索相似物品（用于历史数据复用）
  Future<List<Item>> searchSimilarItems(String name) async {
    if (name.isEmpty) {
      return [];
    }
    return await _dbService.searchSimilarItems(name);
  }
}

/// 数据库服务 Provider
final databaseServiceProvider = Provider<DatabaseService>((ref) {
  return DatabaseService();
});

/// 物品状态 Provider
final itemsProvider = StateNotifierProvider<ItemsNotifier, ItemsState>((ref) {
  final dbService = ref.watch(databaseServiceProvider);
  return ItemsNotifier(dbService);
});

/// 获取单个物品的 Provider
final itemByIdProvider = Provider.family<Item?, String>((ref, id) {
  final state = ref.watch(itemsProvider);
  return state.items.where((item) => item.id == id).firstOrNull;
});

/// 物品统计 Provider
final itemStatsProvider = Provider<ItemStats>((ref) {
  final state = ref.watch(itemsProvider);
  return state.stats;
});

/// 最近添加的物品Provider
final recentItemsProvider = FutureProvider<List<Item>>((ref) async {
  final dbService = ref.watch(databaseServiceProvider);
  return await dbService.getRecentItems(limit: 5);
});

/// 默认AI配置Provider
final defaultAIConfigProvider = FutureProvider<AIConfig?>((ref) async {
  final dbService = ref.watch(databaseServiceProvider);
  return await dbService.getAIConfig();
});
