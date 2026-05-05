import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/ai_config.dart';
import '../providers/ai_config_list_provider.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import '../theme/spacing.dart';
import 'ai_config_edit_page.dart';

/// AI配置列表页面 - 管理多个AI服务配置
class AIConfigListPage extends ConsumerWidget {
  const AIConfigListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(aiConfigListProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text(
          'AI 服务配置',
          style: AppTypography.headlineMd.copyWith(
            color: AppColors.onSurface,
          ),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      body: state.isLoading && state.configs.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : state.configs.isEmpty
              ? _buildEmptyState(context)
              : _buildConfigList(context, ref, state),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToEdit(context, null),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        icon: const Icon(Icons.add),
        label: Text(
          '添加配置',
          style: AppTypography.bodyBase.copyWith(
            color: AppColors.onPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  /// 空状态展示
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.settings_outlined,
              size: 64,
              color: AppColors.onSurfaceVariant.withOpacity(0.4),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              '暂无AI配置',
              style: AppTypography.titleLg.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '点击下方按钮添加AI服务配置',
              style: AppTypography.bodySm.copyWith(
                color: AppColors.onSurfaceVariant.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 配置列表
  Widget _buildConfigList(
    BuildContext context,
    WidgetRef ref,
    AIConfigListState state,
  ) {
    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(aiConfigListProvider.notifier).loadConfigs();
      },
      child: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: state.configs.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (context, index) {
          final config = state.configs[index];
          return _buildConfigCard(context, ref, config);
        },
      ),
    );
  }

  /// 单个配置卡片
  Widget _buildConfigCard(
    BuildContext context,
    WidgetRef ref,
    AIConfig config,
  ) {
    final displayName = config.displayName ?? config.provider.name;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.medium,
        side: BorderSide(
          color: config.isDefault
              ? AppColors.primary.withOpacity(0.5)
              : AppColors.outlineVariant,
          width: config.isDefault ? 1.5 : 1,
        ),
      ),
      color: AppColors.surfaceContainerLowest,
      child: InkWell(
        borderRadius: AppRadius.medium,
        onTap: () => _navigateToEdit(context, config),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 顶部：提供商图标 + 名称 + 默认标记 + 状态指示
              Row(
                children: [
                  // 提供商图标
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: config.provider.isPreset
                          ? AppColors.primaryContainer.withOpacity(0.3)
                          : AppColors.surfaceContainerHigh,
                      borderRadius: AppRadius.small,
                    ),
                    child: Icon(
                      config.provider.isPreset ? Icons.stars : Icons.edit,
                      size: 20,
                      color: config.provider.isPreset
                          ? AppColors.primary
                          : AppColors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),

                  // 名称和模型信息
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                displayName,
                                style: AppTypography.bodyBase.copyWith(
                                  color: AppColors.onSurface,
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (config.isDefault) ...[
                              const SizedBox(width: AppSpacing.xs),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryContainer,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '默认',
                                  style: AppTypography.bodySm.copyWith(
                                    color: AppColors.onPrimaryContainer,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          config.defaultModel,
                          style: AppTypography.bodySm.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),

                  // 状态指示灯
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: config.enabled
                          ? AppColors.primary
                          : AppColors.onSurfaceVariant.withOpacity(0.4),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.sm),

              // 底部操作按钮
              Row(
                children: [
                  // 设为默认
                  if (!config.isDefault)
                    _buildActionButton(
                      label: '设为默认',
                      icon: Icons.star_border,
                      onPressed: () => _setDefault(ref, config),
                    ),

                  // 编辑
                  _buildActionButton(
                    label: '编辑',
                    icon: Icons.edit_outlined,
                    onPressed: () => _navigateToEdit(context, config),
                  ),

                  const Spacer(),

                  // 更多菜单
                  _buildActionButton(
                    label: '更多',
                    icon: Icons.more_horiz,
                    onPressed: () => _showMoreMenu(context, ref, config),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 操作按钮
  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: TextButton.styleFrom(
        foregroundColor: AppColors.onSurfaceVariant,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        textStyle: AppTypography.bodySm.copyWith(
          color: AppColors.onSurfaceVariant,
        ),
      ),
    );
  }

  /// 设为默认配置
  Future<void> _setDefault(WidgetRef ref, AIConfig config) async {
    await ref.read(aiConfigListProvider.notifier).setDefault(config.id);
  }

  /// 跳转到编辑页面
  void _navigateToEdit(BuildContext context, AIConfig? config) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AIConfigEditPage(config: config),
      ),
    );
  }

  /// 显示更多操作菜单
  void _showMoreMenu(
    BuildContext context,
    WidgetRef ref,
    AIConfig config,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 拖拽指示条
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: AppSpacing.sm, bottom: AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // 复制配置
              ListTile(
                leading: const Icon(Icons.copy, color: AppColors.onSurfaceVariant),
                title: Text(
                  '复制配置',
                  style: AppTypography.bodyBase.copyWith(
                    color: AppColors.onSurface,
                  ),
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  _duplicateConfig(ref, config);
                },
              ),

              // 删除配置（非预设才显示）
              if (!config.isDefault)
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: AppColors.error),
                  title: Text(
                    '删除配置',
                    style: AppTypography.bodyBase.copyWith(
                      color: AppColors.error,
                    ),
                  ),
                  onTap: () {
                    Navigator.of(context).pop();
                    _confirmDelete(context, ref, config);
                  },
                ),

              const SizedBox(height: AppSpacing.sm),
            ],
          ),
        );
      },
    );
  }

  /// 复制配置
  Future<void> _duplicateConfig(WidgetRef ref, AIConfig config) async {
    await ref.read(aiConfigListProvider.notifier).duplicateConfig(config.id);
  }

  /// 确认删除对话框
  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    AIConfig config,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('删除配置'),
          content: Text(
            '确定要删除配置"${config.displayName ?? config.provider.name}"吗？此操作不可撤销。',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: AppColors.error),
              child: const Text('删除'),
            ),
          ],
        );
      },
    );

    if (confirmed == true && context.mounted) {
      await ref.read(aiConfigListProvider.notifier).deleteConfig(config.id);
    }
  }
}
