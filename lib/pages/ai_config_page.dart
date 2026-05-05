import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../models/ai_config.dart';
import '../services/database_service.dart';
import '../services/ai_service.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import '../theme/spacing.dart';
import '../utils/constants.dart';

/// AI配置状态
class AIConfigState {
  final AIConfig? config;
  final bool isLoading;
  final String? error;

  const AIConfigState({
    this.config,
    this.isLoading = false,
    this.error,
  });

  AIConfigState copyWith({
    AIConfig? config,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return AIConfigState(
      config: config ?? this.config,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// AI配置Notifier
class AIConfigNotifier extends StateNotifier<AIConfigState> {
  final DatabaseService _dbService;
  final AIService _aiService;

  AIConfigNotifier(this._dbService, this._aiService) : super(const AIConfigState()) {
    loadConfig();
  }

  Future<void> loadConfig() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final config = await _dbService.getAIConfig();
      state = state.copyWith(config: config, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> saveConfig(AIConfig config) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _dbService.saveAIConfig(config);
      state = state.copyWith(config: config, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// 真正测试AI配置连接
  Future<ConnectionTestResult> testConnection(AIConfig config) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final result = await _aiService.testConnection(config);
      state = state.copyWith(isLoading: false);
      return result;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return ConnectionTestResult(success: false, errorMessage: e.toString());
    }
  }
}

/// 数据库服务Provider
final dbServiceProvider = Provider<DatabaseService>((ref) => DatabaseService());

/// AI服务Provider
final aiServiceProvider = Provider<AIService>((ref) => AIService());

/// AI配置Provider
final aiConfigProvider = StateNotifierProvider<AIConfigNotifier, AIConfigState>((ref) {
  return AIConfigNotifier(ref.watch(dbServiceProvider), ref.watch(aiServiceProvider));
});

/// AI配置页面
class AIConfigPage extends ConsumerStatefulWidget {
  const AIConfigPage({super.key});

  @override
  ConsumerState<AIConfigPage> createState() => _AIConfigPageState();
}

class _AIConfigPageState extends ConsumerState<AIConfigPage> {
  final _formKey = GlobalKey<FormState>();
  final _apiKeyController = TextEditingController();
  final _timeoutController = TextEditingController(text: '30');
  final _baseUrlController = TextEditingController();
  final _displayNameController = TextEditingController();
  final _customModelController = TextEditingController();

  AIProvider _selectedProvider = AIProvider.doubao;
  String _selectedModel = 'doubao-1.5-vision-pro';
  bool _enabled = true;
  bool _isTesting = false;
  bool _initialized = false;

  @override
  void dispose() {
    _apiKeyController.dispose();
    _timeoutController.dispose();
    _baseUrlController.dispose();
    _displayNameController.dispose();
    _customModelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(aiConfigProvider);

    // 如果有配置，填充表单（只执行一次）
    if (state.config != null && !_initialized) {
      _initialized = true;
      final config = state.config!;
      _selectedProvider = config.provider;
      _selectedModel = config.defaultModel;
      _apiKeyController.text = config.apiKey;
      _timeoutController.text = config.timeoutSeconds.toString();
      _enabled = config.enabled;
      if (config.baseUrl != null) {
        _baseUrlController.text = config.baseUrl!;
      }
      if (config.displayName != null) {
        _displayNameController.text = config.displayName!;
      }
      // 自定义模型名
      if (config.provider == AIProvider.custom) {
        _customModelController.text = config.defaultModel;
      }
    }

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text(
          'AI 配置',
          style: AppTypography.headlineMd.copyWith(
            color: AppColors.onSurface,
          ),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _saveConfig,
            child: Text(
              '保存',
              style: AppTypography.bodyBase.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [
                  // AI服务状态
                  _buildStatusCard(state),
                  const SizedBox(height: AppSpacing.lg),

                  // 模型提供商选择
                  Text(
                    '模型提供商',
                    style: AppTypography.titleLg.copyWith(
                      color: AppColors.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _buildProviderSelector(),
                  const SizedBox(height: AppSpacing.lg),

                  // 自定义提供商配置（仅自定义时显示）
                  if (_selectedProvider == AIProvider.custom) ...[
                    Text(
                      'API地址',
                      style: AppTypography.titleLg.copyWith(
                        color: AppColors.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextFormField(
                      controller: _baseUrlController,
                      decoration: const InputDecoration(
                        hintText: '例如: https://api.openai.com/v1',
                        helperText: '支持OpenAI兼容格式的API地址',
                      ),
                      validator: (value) {
                        if (_selectedProvider == AIProvider.custom &&
                            (value == null || value.isEmpty)) {
                          return '请输入API地址';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    Text(
                      '配置名称（可选）',
                      style: AppTypography.titleLg.copyWith(
                        color: AppColors.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextFormField(
                      controller: _displayNameController,
                      decoration: const InputDecoration(
                        hintText: '例如: 我的AI',
                        helperText: '方便识别不同的配置',
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ],

                  // API Key输入
                  Text(
                    'API Key',
                    style: AppTypography.titleLg.copyWith(
                      color: AppColors.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextFormField(
                    controller: _apiKeyController,
                    decoration: const InputDecoration(
                      hintText: '输入API Key',
                      helperText: 'API Key将加密存储在本地',
                    ),
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '请输入API Key';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // 默认模型选择/输入
                  Text(
                    '默认模型',
                    style: AppTypography.titleLg.copyWith(
                      color: AppColors.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _selectedProvider == AIProvider.custom
                      ? TextFormField(
                          controller: _customModelController,
                          decoration: const InputDecoration(
                            hintText: '例如: gpt-4o, claude-3-opus',
                            helperText: '输入模型名称',
                          ),
                          validator: (value) {
                            if (_selectedProvider == AIProvider.custom &&
                                (value == null || value.isEmpty)) {
                              return '请输入模型名称';
                            }
                            return null;
                          },
                        )
                      : _buildModelSelector(),
                  const SizedBox(height: AppSpacing.lg),

                  // 超时设置
                  Text(
                    '超时设置',
                    style: AppTypography.titleLg.copyWith(
                      color: AppColors.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextFormField(
                    controller: _timeoutController,
                    decoration: const InputDecoration(
                      labelText: '超时时间（秒）',
                      hintText: '30',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '请输入超时时间';
                      }
                      final timeout = int.tryParse(value);
                      if (timeout == null || timeout < 10) {
                        return '超时时间至少10秒';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // 启用开关
                  SwitchListTile(
                    title: Text(
                      '启用AI服务',
                      style: AppTypography.bodyBase.copyWith(
                        color: AppColors.onSurface,
                      ),
                    ),
                    subtitle: Text(
                      _enabled ? '已启用' : '已禁用',
                      style: AppTypography.bodySm.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    value: _enabled,
                    onChanged: (value) {
                      setState(() => _enabled = value);
                    },
                    activeColor: AppColors.primary,
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // 测试连接按钮
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isTesting ? null : _testConnection,
                      icon: _isTesting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.wifi_find),
                      label: Text(_isTesting ? '测试中...' : '测试连接'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildStatusCard(AIConfigState state) {
    final isConfigured = state.config?.apiKey.isNotEmpty ?? false;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isConfigured
            ? AppColors.primaryContainer.withOpacity(0.3)
            : AppColors.errorContainer.withOpacity(0.3),
        borderRadius: AppRadius.large,
      ),
      child: Row(
        children: [
          Icon(
            isConfigured ? Icons.check_circle : Icons.error_outline,
            color: isConfigured ? AppColors.primary : AppColors.error,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isConfigured ? 'AI服务已配置' : 'AI服务未配置',
                  style: AppTypography.bodyBase.copyWith(
                    color: isConfigured ? AppColors.primary : AppColors.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (state.config != null)
                  Text(
                    '当前模型: ${state.config!.provider.name}',
                    style: AppTypography.bodySm.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProviderSelector() {
    return DropdownButtonFormField<AIProvider>(
      value: _selectedProvider,
      decoration: const InputDecoration(
        hintText: '选择模型提供商',
      ),
      items: AIProvider.values.map((provider) {
        return DropdownMenuItem(
          value: provider,
          child: Row(
            children: [
              Icon(
                provider.isPreset ? Icons.stars : Icons.edit,
                size: 20,
                color: provider.isPreset ? AppColors.primary : AppColors.onSurfaceVariant,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(provider.name),
              if (provider.isPreset) ...[
                const SizedBox(width: AppSpacing.xs),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '预设',
                    style: AppTypography.bodySm.copyWith(
                      color: AppColors.primary,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      }).toList(),
      onChanged: (value) {
        if (value != null) {
          setState(() {
            _selectedProvider = value;
            _selectedModel = _getDefaultModel(value);
            // 切换到豆包时设置默认模型
            if (value == AIProvider.doubao) {
              _selectedModel = 'doubao-1.5-vision-pro';
            }
          });
        }
      },
    );
  }

  Widget _buildModelSelector() {
    final models = _getAvailableModels(_selectedProvider);

    return DropdownButtonFormField<String>(
      value: models.contains(_selectedModel) ? _selectedModel : null,
      decoration: const InputDecoration(
        hintText: '选择默认模型',
      ),
      items: models.map((model) {
        return DropdownMenuItem(
          value: model,
          child: Text(model),
        );
      }).toList(),
      onChanged: (value) {
        if (value != null) {
          setState(() => _selectedModel = value);
        }
      },
    );
  }

  List<String> _getAvailableModels(AIProvider provider) {
    switch (provider) {
      case AIProvider.doubao:
        // 豆包视觉/多模态模型（支持图片识别）
        return [
          'doubao-1.5-vision-pro',
          'doubao-seed-1.6',
          'doubao-seed-1.8',
          'doubao-seed-2.0',
          'doubao-seed-2-0-lite-260215',
          'doubao-seed-2-0-pro-260215',
        ];
      case AIProvider.custom:
        return []; // 自定义使用文本输入
    }
  }

  String _getDefaultModel(AIProvider provider) {
    final models = _getAvailableModels(provider);
    return models.isNotEmpty ? models.first : '';
  }

  Future<void> _testConnection() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isTesting = true);

    final config = AIConfig(
      id: 'default',
      provider: _selectedProvider,
      apiKey: _apiKeyController.text,
      defaultModel: _selectedProvider == AIProvider.custom
          ? _customModelController.text
          : _selectedModel,
      baseUrl: _baseUrlController.text.isNotEmpty
          ? _baseUrlController.text
          : null,
      displayName: _displayNameController.text.isNotEmpty
          ? _displayNameController.text
          : null,
      timeoutSeconds: int.tryParse(_timeoutController.text) ?? 30,
      enabled: _enabled,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final result = await ref.read(aiConfigProvider.notifier).testConnection(config);

    setState(() => _isTesting = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.success ? '连接成功！' : '连接失败: ${result.errorMessage ?? "请检查配置"}'),
          backgroundColor: result.success ? AppColors.primary : AppColors.error,
        ),
      );
    }
  }

  Future<void> _saveConfig() async {
    if (!_formKey.currentState!.validate()) return;

    final config = AIConfig(
      id: 'default',
      provider: _selectedProvider,
      apiKey: _apiKeyController.text,
      defaultModel: _selectedProvider == AIProvider.custom
          ? _customModelController.text
          : _selectedModel,
      baseUrl: _baseUrlController.text.isNotEmpty
          ? _baseUrlController.text
          : null,
      displayName: _displayNameController.text.isNotEmpty
          ? _displayNameController.text
          : null,
      timeoutSeconds: int.tryParse(_timeoutController.text) ?? 30,
      enabled: _enabled,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await ref.read(aiConfigProvider.notifier).saveConfig(config);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('配置已保存')),
      );
      Navigator.of(context).pop();
    }
  }
}
