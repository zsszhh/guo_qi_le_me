import 'package:flutter_riverpod/legacy.dart';
import '../models/item.dart';
import '../models/reminder_log.dart';
import '../services/database_service.dart';
import '../utils/status_utils.dart';
import '../utils/constants.dart';
import 'item_provider.dart';

/// 提醒状态
class ReminderState {
  final List<ReminderLog> pendingReminders;
  final List<Item> urgentItems;
  final List<Item> expiringSoonItems;
  final List<Item> expiredItems;
  final bool isLoading;
  final String? error;

  const ReminderState({
    this.pendingReminders = const [],
    this.urgentItems = const [],
    this.expiringSoonItems = const [],
    this.expiredItems = const [],
    this.isLoading = false,
    this.error,
  });

  /// 今日需要关注物品数量
  int get todayAttentionCount {
    return urgentItems.length + expiringSoonItems.length + expiredItems.length;
  }

  ReminderState copyWith({
    List<ReminderLog>? pendingReminders,
    List<Item>? urgentItems,
    List<Item>? expiringSoonItems,
    List<Item>? expiredItems,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return ReminderState(
      pendingReminders: pendingReminders ?? this.pendingReminders,
      urgentItems: urgentItems ?? this.urgentItems,
      expiringSoonItems: expiringSoonItems ?? this.expiringSoonItems,
      expiredItems: expiredItems ?? this.expiredItems,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// 提醒状态管理器
class ReminderNotifier extends StateNotifier<ReminderState> {
  final DatabaseService _dbService;
  final Ref _ref;

  ReminderNotifier(this._dbService, this._ref) : super(const ReminderState()) {
    // 监听 itemsProvider 的变化，自动刷新提醒数据
    _ref.listen<ItemsState>(itemsProvider, (previous, next) {
      // 当物品列表变化时刷新提醒数据
      if (previous?.items != next.items) {
        loadReminders();
      }
    });
    loadReminders();
  }

  /// 加载提醒数据
  Future<void> loadReminders() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      // 获取所有物品
      final items = await _dbService.getAllItems();

      // 按状态分类（跳过已使用的物品）
      final urgentItems = <Item>[];
      final expiringSoonItems = <Item>[];
      final expiredItems = <Item>[];

      for (final item in items) {
        // 跳过已使用的物品
        if (item.status == ItemStatus.consumed) {
          continue;
        }

        final correctStatus = StatusUtils.calculateStatus(item.expiryDate);
        switch (correctStatus) {
          case ItemStatus.urgent:
            urgentItems.add(item);
            break;
          case ItemStatus.expiringSoon:
            expiringSoonItems.add(item);
            break;
          case ItemStatus.expired:
            expiredItems.add(item);
            break;
          case ItemStatus.normal:
            break;
          case ItemStatus.consumed:
            break;
        }
      }

      // 获取待处理提醒
      final pendingReminders = await _dbService.getPendingReminders();

      state = state.copyWith(
        urgentItems: urgentItems,
        expiringSoonItems: expiringSoonItems,
        expiredItems: expiredItems,
        pendingReminders: pendingReminders,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// 从提醒列表中移除物品（立即更新 UI）
  void removeItem(String itemId) {
    state = state.copyWith(
      urgentItems: state.urgentItems.where((item) => item.id != itemId).toList(),
      expiringSoonItems: state.expiringSoonItems.where((item) => item.id != itemId).toList(),
      expiredItems: state.expiredItems.where((item) => item.id != itemId).toList(),
    );
  }

  /// 标记提醒为已读
  Future<void> markAsRead(String reminderLogId) async {
    try {
      final log = await _getReminderLog(reminderLogId);
      if (log != null) {
        await _dbService.updateReminderLog(
          log.copyWith(readAt: DateTime.now()),
        );
        await loadReminders();
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// 标记提醒为已处理
  Future<void> markAsActioned(String reminderLogId) async {
    try {
      final log = await _getReminderLog(reminderLogId);
      if (log != null) {
        await _dbService.updateReminderLog(
          log.copyWith(actionedAt: DateTime.now()),
        );
        await loadReminders();
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<ReminderLog?> _getReminderLog(String id) async {
    // 从待处理提醒中查找
    for (final log in state.pendingReminders) {
      if (log.id == id) {
        return log;
      }
    }
    return null;
  }
}

/// 数据库服务 Provider
final databaseServiceProvider = Provider<DatabaseService>((ref) {
  return DatabaseService();
});

/// 提醒状态 Provider
final reminderProvider = StateNotifierProvider<ReminderNotifier, ReminderState>((ref) {
  final dbService = ref.watch(databaseServiceProvider);
  return ReminderNotifier(dbService, ref);
});
