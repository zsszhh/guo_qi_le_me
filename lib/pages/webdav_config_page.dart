import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/webdav_config.dart';
import '../services/database_service.dart';
import '../services/webdav_service.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import '../theme/spacing.dart';

/// WebDAV配置状态
class WebDAVConfigState {
  final WebDAVConfig? config;
  final bool isLoading;
  final String? error;
  final SyncStatus syncStatus;

  const WebDAVConfigState({
    this.config,
    this.isLoading = false,
    this.error,
    this.syncStatus = SyncStatus.idle,
  });

  WebDAVConfigState copyWith({
    WebDAVConfig? config,
    bool? isLoading,
    String? error,
    SyncStatus? syncStatus,
    bool clearError = false,
  }) {
    return WebDAVConfigState(
      config: config ?? this.config,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }
}

/// WebDAV配置Notifier
class WebDAVConfigNotifier extends StateNotifier<WebDAVConfigState> {
  final DatabaseService _dbService;
  final WebDAVService _webdavService;

  WebDAVConfigNotifier(this._dbService, this._webdavService) : super(const WebDAVConfigState()) {
    loadConfig();
  }

  Future<void> loadConfig() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final config = await _dbService.getWebDAVConfig();
      state = state.copyWith(config: config, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> saveConfig(WebDAVConfig config) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _dbService.saveWebDAVConfig(config);
      state = state.copyWith(config: config, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<WebDAVConnectionResult> testConnection(WebDAVConfig config) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final result = await _webdavService.testConnection(config);
      state = state.copyWith(isLoading: false);
      return result;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return WebDAVConnectionResult(success: false, errorMessage: e.toString());
    }
  }

  Future<void> sync() async {
    if (state.config == null) return;

    state = state.copyWith(syncStatus: SyncStatus.syncing, clearError: true);
    try {
      await _webdavService.uploadToWebDAV(state.config!);
      state = state.copyWith(
        syncStatus: SyncStatus.idle,
        config: state.config!.copyWith(lastSyncAt: DateTime.now()),
      );
    } catch (e) {
      state = state.copyWith(
        syncStatus: SyncStatus.error,
        error: e.toString(),
      );
    }
  }

  Future<void> syncWithImages() async {
    if (state.config == null) return;

    state = state.copyWith(syncStatus: SyncStatus.syncing, clearError: true);
    try {
      await _webdavService.uploadBackupWithImages(state.config!);
      state = state.copyWith(
        syncStatus: SyncStatus.idle,
        config: state.config!.copyWith(lastSyncAt: DateTime.now()),
      );
    } catch (e) {
      state = state.copyWith(
        syncStatus: SyncStatus.error,
        error: e.toString(),
      );
    }
  }

  Future<List<RemoteBackupInfo>> getRemoteBackups() async {
    if (state.config == null) return [];
    return await _webdavService.listRemoteBackups(state.config!);
  }

  Future<void> restoreBackup(String dbPath, String? imagesPath) async {
    if (state.config == null) return;

    state = state.copyWith(syncStatus: SyncStatus.syncing, clearError: true);
    try {
      await _webdavService.downloadAndRestoreWithImages(
        state.config!,
        dbPath,
        imagesPath,
      );
      state = state.copyWith(syncStatus: SyncStatus.idle);
    } catch (e) {
      state = state.copyWith(
        syncStatus: SyncStatus.error,
        error: e.toString(),
      );
    }
  }
}

/// Provider
final webdavConfigProvider = StateNotifierProvider<WebDAVConfigNotifier, WebDAVConfigState>((ref) {
  return WebDAVConfigNotifier(DatabaseService(), WebDAVService());
});

/// WebDAV配置页面
class WebDAVConfigPage extends ConsumerStatefulWidget {
  const WebDAVConfigPage({super.key});

  @override
  ConsumerState<WebDAVConfigPage> createState() => _WebDAVConfigPageState();
}

class _WebDAVConfigPageState extends ConsumerState<WebDAVConfigPage> {
  final _formKey = GlobalKey<FormState>();
  final _serverUrlController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _remotePathController = TextEditingController(text: '/guo_qi_le_me');
  final _syncIntervalController = TextEditingController(text: '30');

  bool _autoSync = false;
  bool _enabled = false;
  bool _isTesting = false;
  bool _isSyncing = false;
  bool _isSyncingWithImages = false;
  List<RemoteBackupInfo> _remoteBackups = [];

  @override
  void dispose() {
    _serverUrlController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _remotePathController.dispose();
    _syncIntervalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(webdavConfigProvider);

    // 如果有配置，填充表单
    if (state.config != null && _serverUrlController.text.isEmpty) {
      final config = state.config!;
      _serverUrlController.text = config.serverUrl;
      _usernameController.text = config.username;
      _passwordController.text = config.password;
      _remotePathController.text = config.remotePath;
      _syncIntervalController.text = config.syncInterval.toString();
      _autoSync = config.autoSync;
      _enabled = config.enabled;
    }

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text(
          'WebDAV 同步',
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
                  // 同步状态卡片
                  _buildStatusCard(state),
                  const SizedBox(height: AppSpacing.lg),

                  // 服务器配置
                  Text(
                    '服务器配置',
                    style: AppTypography.titleLg.copyWith(
                      color: AppColors.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  TextFormField(
                    controller: _serverUrlController,
                    decoration: const InputDecoration(
                      labelText: '服务器地址',
                      hintText: 'https://example.com/webdav',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '请输入服务器地址';
                      }
                      if (!value.startsWith('http')) {
                        return '请输入有效的URL';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),

                  TextFormField(
                    controller: _usernameController,
                    decoration: const InputDecoration(
                      labelText: '用户名',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '请输入用户名';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),

                  TextFormField(
                    controller: _passwordController,
                    decoration: const InputDecoration(
                      labelText: '密码',
                    ),
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '请输入密码';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),

                  TextFormField(
                    controller: _remotePathController,
                    decoration: const InputDecoration(
                      labelText: '远程路径',
                      hintText: '/guo_qi_le_me',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // 同步设置
                  Text(
                    '同步设置',
                    style: AppTypography.titleLg.copyWith(
                      color: AppColors.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  SwitchListTile(
                    title: Text(
                      '启用同步',
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

                  SwitchListTile(
                    title: Text(
                      '自动同步',
                      style: AppTypography.bodyBase.copyWith(
                        color: AppColors.onSurface,
                      ),
                    ),
                    subtitle: Text(
                      _autoSync ? '已启用' : '已禁用',
                      style: AppTypography.bodySm.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    value: _autoSync,
                    onChanged: (value) {
                      setState(() => _autoSync = value);
                    },
                    activeColor: AppColors.primary,
                  ),

                  TextFormField(
                    controller: _syncIntervalController,
                    decoration: const InputDecoration(
                      labelText: '同步间隔（分钟）',
                    ),
                    keyboardType: TextInputType.number,
                    enabled: _autoSync,
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // 操作按钮
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
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
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isSyncing || !_enabled ? null : _syncNow,
                          icon: _isSyncing
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.sync),
                          label: Text(_isSyncing ? '同步中...' : '立即同步'),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: AppSpacing.md),

                  // 完整备份按钮（含图片）
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isSyncingWithImages || !_enabled ? null : _syncWithImages,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryContainer,
                        foregroundColor: AppColors.primary,
                      ),
                      icon: _isSyncingWithImages
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.cloud_upload),
                      label: Text(_isSyncingWithImages ? '备份中...' : '完整备份（含图片）'),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.md),

                  // 恢复按钮
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: !_enabled ? null : _showRestoreDialog,
                      icon: const Icon(Icons.cloud_download),
                      label: const Text('从云端恢复'),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // 常用WebDAV服务提示
                  _buildServiceTips(),
                ],
              ),
            ),
    );
  }

  Widget _buildStatusCard(WebDAVConfigState state) {
    final isConfigured = state.config?.serverUrl.isNotEmpty ?? false;
    final lastSync = state.config?.lastSyncAt;

    Color statusColor;
    String statusText;
    IconData statusIcon;

    if (state.syncStatus == SyncStatus.syncing) {
      statusColor = AppColors.primary;
      statusText = '正在同步...';
      statusIcon = Icons.sync;
    } else if (state.syncStatus == SyncStatus.error) {
      statusColor = AppColors.error;
      statusText = '同步失败';
      statusIcon = Icons.error_outline;
    } else if (isConfigured) {
      statusColor = AppColors.primary;
      statusText = '已配置';
      statusIcon = Icons.check_circle;
    } else {
      statusColor = AppColors.onSurfaceVariant;
      statusText = '未配置';
      statusIcon = Icons.cloud_off;
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: AppRadius.large,
      ),
      child: Row(
        children: [
          Icon(statusIcon, color: statusColor),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  statusText,
                  style: AppTypography.bodyBase.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (lastSync != null)
                  Text(
                    '上次同步: ${_formatDateTime(lastSync)}',
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

  Widget _buildServiceTips() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: AppRadius.large,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: AppColors.primary, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Text(
                '常用WebDAV服务',
                style: AppTypography.bodyBase.copyWith(
                  color: AppColors.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '• 坚果云: https://dav.jianguoyun.com/dav/\n'
            '• Nextcloud: https://your-server/remote.php/dav/\n'
            '• OwnCloud: https://your-server/remote.php/webdav/',
            style: AppTypography.bodySm.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _testConnection() async {
    if (!_formKey.currentState!.validate()) return;

    final config = WebDAVConfig(
      id: 'default',
      serverUrl: _serverUrlController.text,
      username: _usernameController.text,
      password: _passwordController.text,
      remotePath: _remotePathController.text,
      syncInterval: int.tryParse(_syncIntervalController.text) ?? 30,
      autoSync: _autoSync,
      enabled: _enabled,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    setState(() => _isTesting = true);
    final result = await ref.read(webdavConfigProvider.notifier).testConnection(config);
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

  Future<void> _syncNow() async {
    setState(() => _isSyncing = true);
    await ref.read(webdavConfigProvider.notifier).sync();
    setState(() => _isSyncing = false);

    if (mounted) {
      final state = ref.read(webdavConfigProvider);
      if (state.syncStatus != SyncStatus.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('同步成功！')),
        );
      }
    }
  }

  Future<void> _saveConfig() async {
    if (!_formKey.currentState!.validate()) return;

    final config = WebDAVConfig(
      id: 'default',
      serverUrl: _serverUrlController.text,
      username: _usernameController.text,
      password: _passwordController.text,
      remotePath: _remotePathController.text,
      syncInterval: int.tryParse(_syncIntervalController.text) ?? 30,
      autoSync: _autoSync,
      enabled: _enabled,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await ref.read(webdavConfigProvider.notifier).saveConfig(config);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('配置已保存')),
      );
      Navigator.of(context).pop();
    }
  }

  Future<void> _syncWithImages() async {
    setState(() => _isSyncingWithImages = true);
    await ref.read(webdavConfigProvider.notifier).syncWithImages();
    setState(() => _isSyncingWithImages = false);

    if (mounted) {
      final state = ref.read(webdavConfigProvider);
      if (state.syncStatus != SyncStatus.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('备份成功（含图片）！')),
        );
      }
    }
  }

  Future<void> _showRestoreDialog() async {
    setState(() => _isSyncing = true);

    try {
      final backups = await ref.read(webdavConfigProvider.notifier).getRemoteBackups();

      setState(() {
        _remoteBackups = backups;
        _isSyncing = false;
      });

      if (!mounted) return;

      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (context) => DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          minChildSize: 0.3,
          expand: false,
          builder: (context, scrollController) => Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Row(
                  children: [
                    Text(
                      '选择备份文件',
                      style: AppTypography.titleLg.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('取消'),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: _remoteBackups.isEmpty
                    ? const Center(child: Text('暂无备份文件'))
                    : ListView.builder(
                        controller: scrollController,
                        itemCount: _remoteBackups.length,
                        itemBuilder: (context, index) {
                          final backup = _remoteBackups[index];
                          final isImageBackup = backup.name.contains('_images.zip');

                          if (isImageBackup) return const SizedBox.shrink();

                          // 查找对应的图片备份
                          final baseName = backup.name.replaceAll('.db', '');
                          final imageBackup = _remoteBackups.firstWhere(
                            (b) => b.name == '${baseName}_images.zip',
                            orElse: () => backup,
                          );

                          return ListTile(
                            leading: const Icon(Icons.backup),
                            title: Text(backup.name),
                            subtitle: Text(
                              '${_formatFileSize(backup.size)} · ${_formatDateTime(backup.modifiedTime)}',
                            ),
                            onTap: () async {
                              Navigator.pop(context);
                              await _restoreBackup(
                                backup.path,
                                imageBackup.name.contains('.zip') ? imageBackup.path : null,
                              );
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      setState(() => _isSyncing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('获取备份列表失败: $e')),
        );
      }
    }
  }

  Future<void> _restoreBackup(String dbPath, String? imagesPath) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认恢复'),
        content: const Text('恢复将覆盖当前数据，此操作不可撤销。确定要继续吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('确认恢复'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isSyncing = true);

    try {
      await ref.read(webdavConfigProvider.notifier).restoreBackup(dbPath, imagesPath);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('恢复成功！请重启应用')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('恢复失败: $e')),
        );
      }
    } finally {
      setState(() => _isSyncing = false);
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
