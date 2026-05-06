import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import '../theme/spacing.dart';
import '../models/reminder_config.dart';
import '../services/database_service.dart';
import '../services/background_service.dart';

/// 提醒配置页面
class ReminderConfigPage extends ConsumerStatefulWidget {
  const ReminderConfigPage({super.key});

  @override
  ConsumerState<ReminderConfigPage> createState() => _ReminderConfigPageState();
}

class _ReminderConfigPageState extends ConsumerState<ReminderConfigPage> {
  final DatabaseService _dbService = DatabaseService();

  bool _remind3Days = true;
  bool _remind7Days = true;
  bool _remind14Days = true;
  bool _pushNotification = true;
  bool _soundEnabled = true;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 9, minute: 0);
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    final config = await _dbService.getReminderConfig();
    if (config != null && mounted) {
      setState(() {
        _remind3Days = config.remind3Days;
        _remind7Days = config.remind7Days;
        _remind14Days = config.remind14Days;
        _pushNotification = config.pushNotification;
        _soundEnabled = config.soundEnabled;
        final parts = config.reminderTime.split(':');
        if (parts.length == 2) {
          _reminderTime = TimeOfDay(
            hour: int.parse(parts[0]),
            minute: int.parse(parts[1]),
          );
        }
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveConfig() async {
    setState(() => _isSaving = true);

    try {
      final config = ReminderConfig(
        id: 'default',
        remind3Days: _remind3Days,
        remind7Days: _remind7Days,
        remind14Days: _remind14Days,
        pushNotification: _pushNotification,
        reminderTime: '${_reminderTime.hour.toString().padLeft(2, '0')}:${_reminderTime.minute.toString().padLeft(2, '0')}',
        soundEnabled: _soundEnabled,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _dbService.saveReminderConfig(config);

      // 更新后台任务调度
      final backgroundService = BackgroundService();
      if (config.pushNotification) {
        await backgroundService.scheduleDailyReminder(
          reminderTime: config.reminderTime,
        );
      } else {
        await backgroundService.cancelAllTasks();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('提醒配置已保存')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存失败: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _reminderTime,
    );
    if (picked != null) {
      setState(() => _reminderTime = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text(
          '提醒配置',
          style: AppTypography.headlineMd.copyWith(
            color: AppColors.onSurface,
          ),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
        actions: [
          _isSaving
              ? const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : TextButton(
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                // 提醒时间设置
                _buildSection('提醒时间'),
                ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer.withValues(alpha:0.3),
                      borderRadius: AppRadius.medium,
                    ),
                    child: Icon(Icons.access_time, color: AppColors.primary, size: 22),
                  ),
                  title: const Text('提醒时间'),
                  subtitle: Text(
                    '${_reminderTime.hour.toString().padLeft(2, '0')}:${_reminderTime.minute.toString().padLeft(2, '0')}',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _selectTime,
                ),
                const Divider(),

                // 提醒天数设置
                _buildSection('提醒天数'),
                SwitchListTile(
                  secondary: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha:0.1),
                      borderRadius: AppRadius.medium,
                    ),
                    child: Icon(Icons.warning_amber, color: AppColors.error, size: 22),
                  ),
                  title: const Text('提前3天提醒'),
                  subtitle: const Text('急需处理时提醒'),
                  value: _remind3Days,
                  onChanged: (value) => setState(() => _remind3Days = value),
                ),
                SwitchListTile(
                  secondary: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withValues(alpha:0.1),
                      borderRadius: AppRadius.medium,
                    ),
                    child: Icon(Icons.schedule, color: AppColors.secondary, size: 22),
                  ),
                  title: const Text('提前7天提醒'),
                  subtitle: const Text('即将过期时提醒'),
                  value: _remind7Days,
                  onChanged: (value) => setState(() => _remind7Days = value),
                ),
                SwitchListTile(
                  secondary: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha:0.1),
                      borderRadius: AppRadius.medium,
                    ),
                    child: Icon(Icons.event, color: AppColors.primary, size: 22),
                  ),
                  title: const Text('提前14天提醒'),
                  subtitle: const Text('充足准备时间'),
                  value: _remind14Days,
                  onChanged: (value) => setState(() => _remind14Days = value),
                ),
                const Divider(),

                // 通知设置
                _buildSection('通知方式'),
                SwitchListTile(
                  secondary: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer.withValues(alpha:0.3),
                      borderRadius: AppRadius.medium,
                    ),
                    child: Icon(Icons.notifications, color: AppColors.primary, size: 22),
                  ),
                  title: const Text('推送通知'),
                  subtitle: const Text('接收系统推送通知'),
                  value: _pushNotification,
                  onChanged: (value) => setState(() => _pushNotification = value),
                ),
                SwitchListTile(
                  secondary: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer.withValues(alpha:0.3),
                      borderRadius: AppRadius.medium,
                    ),
                    child: Icon(Icons.volume_up, color: AppColors.primary, size: 22),
                  ),
                  title: const Text('提示音'),
                  subtitle: const Text('播放提示音'),
                  value: _soundEnabled,
                  onChanged: (value) => setState(() => _soundEnabled = value),
                ),
                const SizedBox(height: AppSpacing.xl),

                // 说明文字
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainer.withValues(alpha:0.5),
                      borderRadius: AppRadius.medium,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info_outline, size: 18, color: AppColors.onSurfaceVariant),
                            const SizedBox(width: AppSpacing.sm),
                            Text(
                              '说明',
                              style: AppTypography.titleLg.copyWith(
                                color: AppColors.onSurfaceVariant,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          '• 提醒会在每天的设定时间自动检查\n'
                          '• 需要开启系统通知权限\n'
                          '• 关闭应用后仍可接收提醒',
                          style: AppTypography.bodySm.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSection(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: Text(
        title,
        style: AppTypography.titleLg.copyWith(
          color: AppColors.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
