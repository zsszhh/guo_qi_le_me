import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/ai_config.dart';
import '../services/database_service.dart';
import '../services/ai_service.dart';
import 'item_provider.dart'; // 引用 databaseServiceProvider

/// AI配置列表状态
class AIConfigListState {
  final List<AIConfig> configs;
  final bool isLoading;
  final String? error;

  const AIConfigListState({
    this.configs = const [],
    this.isLoading = false,
    this.error,
  });

  /// 获取默认配置
  AIConfig? get defaultConfig {
    for (final config in configs) {
      if (config.isDefault) return config;
    }
    // 兜底：如果无标记默认配置，返回第一个
    return configs.isNotEmpty ? configs.first : null;
  }

  AIConfigListState copyWith({
    List<AIConfig>? configs,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return AIConfigListState(
      configs: configs ?? this.configs,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// AI配置列表状态管理器
class AIConfigListNotifier extends StateNotifier<AIConfigListState> {
  final DatabaseService _dbService;
  final AIService _aiService;

  AIConfigListNotifier(this._dbService, this._aiService)
      : super(const AIConfigListState()) {
    loadConfigs();
  }

  /// 加载所有AI配置
  Future<void> loadConfigs() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final configs = await _dbService.getAllAIConfigs();
      state = state.copyWith(configs: configs, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// 保存AI配置（新增或更新）
  Future<void> saveConfig(AIConfig config) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _dbService.saveAIConfig(config);
      await loadConfigs();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// 删除AI配置
  Future<void> deleteConfig(String id) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _dbService.deleteAIConfig(id);
      await loadConfigs();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// 设置默认AI配置
  Future<void> setDefault(String id) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _dbService.setDefaultAIConfig(id);
      await loadConfigs();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// 复制AI配置
  Future<void> duplicateConfig(String id) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _dbService.duplicateAIConfig(id);
      await loadConfigs();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// 测试AI配置连接
  Future<ConnectionTestResult> testConnection(AIConfig config) async {
    return await _aiService.testConnection(config);
  }
}

/// AI配置列表 Provider
final aiConfigListProvider =
    StateNotifierProvider<AIConfigListNotifier, AIConfigListState>((ref) {
  final dbService = ref.watch(databaseServiceProvider);
  final aiService = AIService();
  return AIConfigListNotifier(dbService, aiService);
});
