import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'database_service.dart';
import '../models/backup_history.dart';
import '../utils/constants.dart';
import '../utils/date_utils.dart' as app_date_utils;

/// 备份服务
class BackupService {
  static final BackupService _instance = BackupService._internal();
  factory BackupService() => _instance;
  BackupService._internal();

  final DatabaseService _dbService = DatabaseService();

  /// 备份目录名
  static const String _backupDirName = 'backups';

  /// 获取备份目录路径
  Future<String> get _backupDirPath async {
    final appDir = await getApplicationDocumentsDirectory();
    final backupDir = Directory(p.join(appDir.path, _backupDirName));
    if (!await backupDir.exists()) {
      await backupDir.create(recursive: true);
    }
    return backupDir.path;
  }

  /// 创建本地备份
  Future<BackupHistory> createLocalBackup() async {
    final now = DateTime.now();
    final backupId = _generateId();
    final backupFileName = 'backup_${app_date_utils.DateUtils.formatDateForFileName(now)}.db';

    try {
      // 获取数据库路径
      final dbPath = await getDatabasesPath();
      final dbFile = File(p.join(dbPath, DatabaseService.databaseName));

      if (!await dbFile.exists()) {
        throw Exception('数据库文件不存在');
      }

      // 复制到备份目录
      final backupDir = await _backupDirPath;
      final backupFilePath = p.join(backupDir, backupFileName);
      await dbFile.copy(backupFilePath);

      // 获取文件大小
      final fileSize = await File(backupFilePath).length();

      // 记录备份历史
      final history = BackupHistory(
        id: backupId,
        backupType: BackupType.local,
        status: BackupStatus.success,
        filePath: backupFilePath,
        fileSizeBytes: fileSize,
        backupAt: now,
        createdAt: now,
      );

      await _dbService.insertBackupHistory(history);
      return history;
    } catch (e) {
      // 记录失败历史
      final history = BackupHistory(
        id: backupId,
        backupType: BackupType.local,
        status: BackupStatus.failed,
        errorMessage: e.toString(),
        backupAt: now,
        createdAt: now,
      );

      await _dbService.insertBackupHistory(history);
      rethrow;
    }
  }

  /// 从本地备份恢复
  Future<void> restoreFromLocalBackup(String backupFilePath) async {
    try {
      final backupFile = File(backupFilePath);
      if (!await backupFile.exists()) {
        throw Exception('备份文件不存在');
      }

      // 关闭当前数据库连接
      await _dbService.close();

      // 获取数据库路径
      final dbPath = await getDatabasesPath();
      final dbFilePath = p.join(dbPath, DatabaseService.databaseName);

      // 复制备份文件覆盖当前数据库
      await backupFile.copy(dbFilePath);
    } catch (e) {
      rethrow;
    }
  }

  /// 获取本地备份列表
  Future<List<BackupHistory>> getLocalBackups() async {
    return await _dbService.getBackupHistory(limit: 20);
  }

  /// 删除本地备份
  Future<void> deleteLocalBackup(String backupId, String? filePath) async {
    // 删除文件
    if (filePath != null) {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }
    }

    // 从历史记录中删除（需要在 DatabaseService 中添加方法）
    // 暂时保留历史记录
  }

  /// 清理旧备份（保留最近N个）
  Future<void> cleanupOldBackups({int keepCount = 10}) async {
    final history = await _dbService.getBackupHistory();

    if (history.length <= keepCount) return;

    final toDelete = history.skip(keepCount);
    for (final record in toDelete) {
      if (record.filePath != null) {
        final file = File(record.filePath!);
        if (await file.exists()) {
          await file.delete();
        }
      }
    }
  }

  /// 生成唯一ID
  String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }
}
