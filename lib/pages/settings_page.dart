import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import '../theme/spacing.dart';
import '../services/backup_service.dart';
import 'ai_config_list_page.dart';
import 'webdav_config_page.dart';
import 'reminder_config_page.dart';
import 'reminder_center_page.dart';
import 'privacy_policy_page.dart';

/// 设置页面
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text(
          '设置',
          style: AppTypography.headlineMd.copyWith(
            color: AppColors.onSurface,
          ),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
        children: [
          // AI 配置卡片
          _buildSettingsCard(
            title: 'AI 配置',
            children: [
              _buildSettingsItem(
                icon: Icons.smart_toy,
                title: 'AI 服务配置',
                subtitle: '管理多个AI服务提供商',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const AIConfigListPage(),
                    ),
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.lg),

          // 提醒设置卡片
          _buildSettingsCard(
            title: '提醒设置',
            children: [
              _buildSettingsItem(
                icon: Icons.notifications,
                title: '提醒配置',
                subtitle: '设置提醒时间和方式',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const ReminderConfigPage(),
                    ),
                  );
                },
              ),
              Divider(
                height: 1,
                color: AppColors.outlineVariant.withOpacity(0.3),
              ),
              _buildSettingsItem(
                icon: Icons.history,
                title: '提醒中心',
                subtitle: '查看需要关注的物品',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const ReminderCenterPage(),
                    ),
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.lg),

          // 数据管理卡片
          _buildSettingsCard(
            title: '数据管理',
            children: [
              _buildSettingsItem(
                icon: Icons.cloud_sync,
                title: 'WebDAV 同步',
                subtitle: '配置云端同步',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const WebDAVConfigPage(),
                    ),
                  );
                },
              ),
              Divider(
                height: 1,
                color: AppColors.outlineVariant.withOpacity(0.3),
              ),
              _buildSettingsItem(
                icon: Icons.backup,
                title: '本地备份',
                subtitle: '备份与恢复数据',
                onTap: () => _showBackupOptions(context),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.lg),

          // 关于卡片
          _buildSettingsCard(
            title: '关于',
            children: [
              _buildSettingsItem(
                icon: Icons.info_outline,
                title: '关于应用',
                subtitle: '版本 1.0.0',
                onTap: () => _showAboutDialog(context),
              ),
              Divider(
                height: 1,
                color: AppColors.outlineVariant.withOpacity(0.3),
              ),
              _buildSettingsItem(
                icon: Icons.privacy_tip_outlined,
                title: '隐私政策',
                subtitle: '了解我们如何保护你的数据',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const PrivacyPolicyPage(),
                    ),
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.xl),

          // 版权信息
          Center(
            child: Text(
              '© 2026 过期了么',
              style: AppTypography.bodySm.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  /// 构建设置卡片
  Widget _buildSettingsCard({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: AppRadius.large,
        border: Border.all(
          color: AppColors.outlineVariant.withOpacity(0.3),
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
          // 标题
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.sm,
            ),
            child: Text(
              title,
              style: AppTypography.titleLg.copyWith(
                color: AppColors.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          // 分隔线
          Divider(
            height: 1,
            color: AppColors.outlineVariant.withOpacity(0.3),
          ),
          // 内容
          ...children,
        ],
      ),
    );
  }

  /// 构建设置项
  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
    Color? iconColor,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            // 图标
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: (iconColor ?? AppColors.primary).withOpacity(0.1),
                borderRadius: AppRadius.medium,
              ),
              child: Icon(
                icon,
                color: iconColor ?? AppColors.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            // 文字
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.bodyBase.copyWith(
                      color: AppColors.onSurface,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle,
                      style: AppTypography.bodySm.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
            // 尾部
            if (trailing != null) trailing,
            if (onTap != null && trailing == null)
              const Icon(
                Icons.chevron_right,
                color: AppColors.onSurfaceVariant,
              ),
          ],
        ),
      ),
    );
  }

  void _showBackupOptions(BuildContext context) {
    final backupService = BackupService();

    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.backup),
              title: const Text('创建备份'),
              subtitle: const Text('备份当前数据'),
              onTap: () async {
                Navigator.pop(context);
                try {
                  final history = await backupService.createLocalBackup();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('备份成功: ${history.filePath}')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('备份失败: $e')),
                    );
                  }
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.restore),
              title: const Text('恢复备份'),
              subtitle: const Text('从备份恢复数据'),
              onTap: () async {
                Navigator.pop(context);
                final backups = await backupService.getLocalBackups();
                if (context.mounted) {
                  if (backups.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('没有可用的备份')),
                    );
                    return;
                  }
                  showModalBottomSheet(
                    context: context,
                    builder: (context) => SafeArea(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: backups.map((backup) => ListTile(
                          title: Text(_formatBackupDate(backup.backupAt)),
                          subtitle: Text(
                            '大小: ${(backup.fileSizeBytes! / 1024).toStringAsFixed(1)} KB',
                          ),
                          onTap: () async {
                            Navigator.pop(context);
                            try {
                              await backupService.restoreFromLocalBackup(backup.filePath!);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('恢复成功，请重启应用')),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('恢复失败: $e')),
                                );
                              }
                            }
                          },
                        )).toList(),
                      ),
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  String _formatBackupDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: AppRadius.medium,
              ),
              child: const Icon(Icons.timer, color: Colors.white),
            ),
            const SizedBox(width: AppSpacing.md),
            const Text('过期了么'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('版本: 1.0.0'),
            SizedBox(height: AppSpacing.md),
            Text(
              '过期了么是一款轻量级的物品管理应用，专注于解决日常生活中食品和药品的过期问题。',
            ),
            SizedBox(height: AppSpacing.md),
            Text('主要功能:'),
            SizedBox(height: AppSpacing.sm),
            Text('• AI 智能录入'),
            Text('• 保质期追踪'),
            Text('• 多元提醒'),
            Text('• WebDAV 同步'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
}
