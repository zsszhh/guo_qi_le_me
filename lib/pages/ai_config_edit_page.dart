import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/ai_config.dart';
import '../providers/ai_config_list_provider.dart';
import '../services/secure_storage_service.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import '../theme/spacing.dart';
import '../utils/constants.dart';
import '../widgets/message_toast.dart';

/// AI配置编辑页面
/// 支持新增和编辑两种模式：config 为 null 表示新增，否则为编辑
class AIConfigEditPage extends ConsumerStatefulWidget {
  /// 要编辑的配置，为 null 时表示新增
  final AIConfig? config;

  const AIConfigEditPage({super.key, this.config});

  @override
  ConsumerState<AIConfigEditPage> createState() => _AIConfigEditPageState();
}

class _AIConfigEditPageState extends ConsumerState<AIConfigEditPage> {
  final _formKey = GlobalKey<FormState>();
  final _apiKeyController = TextEditingController();
  final _timeoutController = TextEditingController(text: '30');
  final _baseUrlController = TextEditingController();
  final _displayNameController = TextEditingController();
  final _customModelController = TextEditingController();

  late AIProvider _selectedProvider;
  late String _selectedModel;
  late bool _enabled;
  bool _isTesting = false;

  /// 是否为编辑模式
  bool get _isEditing => widget.config != null;

  @override
  void initState() {
    super.initState();
    // 初始化默认值
    _selectedProvider = AIProvider.doubao;
    _selectedModel = 'doubao-1.5-vision-pro';
    _enabled = true;

    // 编辑模式下异步加载配置
    if (_isEditing && widget.config != null) {
      _loadConfigAsync();
    }
  }

  /// 异步加载配置（编辑模式）
  Future<void> _loadConfigAsync() async {
    final config = widget.config!;
    _selectedProvider = config.provider;
    _selectedModel = config.defaultModel;
    _timeoutController.text = config.timeoutSeconds.toString();
    _enabled = config.enabled;

    if (config.baseUrl != null) {
      _baseUrlController.text = config.baseUrl!;
    }
    if (config.displayName != null) {
      _displayNameController.text = config.displayName!;
    }
    if (config.provider == AIProvider.custom) {
      _customModelController.text = config.defaultModel;
    }

    // 从 SecureStorage 读取 apiKey
    final secureStorage = SecureStorageService();
    final savedApiKey = await secureStorage.getApiKey(config.id);
    _apiKeyController.text = savedApiKey ?? '';

    if (mounted) setState(() {});
  }

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
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text(
          _isEditing ? '编辑配置' : '添加配置',
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
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            // 模型提供商选择
            _buildSectionTitle('模型提供商'),
            const SizedBox(height: AppSpacing.sm),
            _buildProviderSelector(),
            const SizedBox(height: AppSpacing.lg),

            // 自定义提供商配置（仅自定义时显示）
            if (_selectedProvider == AIProvider.custom) ...[
              _buildSectionTitle('API地址'),
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

              _buildSectionTitle('配置名称（可选）'),
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

            // API Key 输入
            _buildSectionTitle('API Key'),
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
            _buildSectionTitle('默认模型'),
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
            _buildSectionTitle('超时设置'),
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
              activeThumbColor: AppColors.primary,
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

  /// 构建分区标题
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: AppTypography.titleLg.copyWith(
        color: AppColors.onSurface,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  /// 构建提供商选择器
  Widget _buildProviderSelector() {
    return DropdownButtonFormField<AIProvider>(
      initialValue: _selectedProvider,
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
                    color: AppColors.primaryContainer.withValues(alpha:0.5),
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
            if (value == AIProvider.doubao) {
              _selectedModel = 'doubao-1.5-vision-pro';
            } else {
              _selectedModel = '';
            }
          });
        }
      },
    );
  }

  /// 构建模型下拉选择器（仅豆包预设使用）
  Widget _buildModelSelector() {
    final models = _getAvailableModels(_selectedProvider);

    return DropdownButtonFormField<String>(
      initialValue: models.contains(_selectedModel) ? _selectedModel : null,
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

  /// 获取指定提供商可用的模型列表
  List<String> _getAvailableModels(AIProvider provider) {
    switch (provider) {
      case AIProvider.doubao:
        return [
          'doubao-1.5-vision-pro',
          'doubao-seed-1.6',
          'doubao-seed-1.8',
          'doubao-seed-2.0',
          'doubao-seed-2-0-lite-260215',
          'doubao-seed-2-0-pro-260215',
        ];
      case AIProvider.custom:
        return [];
    }
  }

  /// 从表单构建 AIConfig 对象
  AIConfig _buildConfigFromForm() {
    final now = DateTime.now();
    // 编辑模式保留原 createdAt，新增模式用当前时间
    final createdAt = widget.config?.createdAt ?? now;

    return AIConfig(
      id: widget.config?.id ?? 'config_${now.millisecondsSinceEpoch}',
      provider: _selectedProvider,
      apiKey: _apiKeyController.text.trim(),
      defaultModel: _selectedProvider == AIProvider.custom
          ? _customModelController.text.trim()
          : _selectedModel,
      baseUrl: _baseUrlController.text.isNotEmpty
          ? _baseUrlController.text.trim()
          : null,
      displayName: _displayNameController.text.isNotEmpty
          ? _displayNameController.text.trim()
          : null,
      timeoutSeconds: int.tryParse(_timeoutController.text) ?? 30,
      enabled: _enabled,
      isDefault: widget.config?.isDefault ?? false,
      createdAt: createdAt,
      updatedAt: now,
    );
  }

  /// 测试连接
  Future<void> _testConnection() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isTesting = true);

    final config = _buildConfigFromForm();

    try {
      final result = await ref.read(aiConfigListProvider.notifier).testConnection(config);

      if (mounted) {
        if (result.success) {
          MessageService.success(context, '连接成功！');
        } else {
          MessageService.error(context, '连接失败: ${result.errorMessage ?? "请检查配置"}');
        }
      }
    } catch (e) {
      if (mounted) {
        MessageService.error(context, '测试出错: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isTesting = false);
      }
    }
  }

  /// 保存配置
  Future<void> _saveConfig() async {
    if (!_formKey.currentState!.validate()) return;

    final config = _buildConfigFromForm();
    final secureStorage = SecureStorageService();

    try {
      // 通过 AIConfigListProvider 保存配置到数据库
      await ref.read(aiConfigListProvider.notifier).saveConfig(config);

      // API Key 加密存储到 SecureStorage
      await secureStorage.saveApiKey(config.id, config.apiKey);

      if (mounted) {
        MessageService.success(context, '配置已保存');
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        MessageService.error(context, '保存失败: $e');
      }
    }
  }
}
