import 'dart:io';
import 'package:archive/archive.dart';
import 'package:archive/archive_io.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'database_service.dart';
import '../models/backup_history.dart';
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

  /// 创建本地备份（包含数据库和产品图）
  Future<BackupHistory> createLocalBackup() async {
    final now = DateTime.now();
    final backupId = _generateId();
    final dateStr = app_date_utils.DateUtils.formatDateForFileName(now);
    final backupFileName = 'backup_$dateStr.db';

    try {
      // 获取数据库路径
      final dbPath = await getDatabasesPath();
      final dbFile = File(p.join(dbPath, DatabaseService.databaseName));

      if (!await dbFile.exists()) {
        throw Exception('数据库文件不存在');
      }

      // 复制数据库到备份目录
      final backupDir = await _backupDirPath;
      final dbBackupPath = p.join(backupDir, backupFileName);
      await dbFile.copy(dbBackupPath);

      int totalSize = await File(dbBackupPath).length();

      // 打包产品图片目录
      final appDir = await getApplicationDocumentsDirectory();
      final imagesDir = Directory('${appDir.path}/item_images');

      if (await imagesDir.exists()) {
        final zipFileName = 'backup_${dateStr}_images.zip';
        final zipPath = p.join(backupDir, zipFileName);

        await _zipDirectory(imagesDir.path, zipPath);

        final zipFile = File(zipPath);
        if (await zipFile.exists()) {
          totalSize += await zipFile.length();
        }
      }

      // 记录备份历史
      final history = BackupHistory(
        id: backupId,
        backupType: BackupType.local,
        status: BackupStatus.success,
        filePath: dbBackupPath,
        fileSizeBytes: totalSize,
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

  /// 从本地备份恢复（包含数据库和产品图）
  /// [dbBackupPath] 数据库备份文件路径
  /// [imagesBackupPath] 图片备份文件路径（可选）
  Future<void> restoreFromLocalBackup(String dbBackupPath, {String? imagesBackupPath}) async {
    try {
      // 恢复数据库
      final dbBackupFile = File(dbBackupPath);
      if (!await dbBackupFile.exists()) {
        throw Exception('数据库备份文件不存在');
      }

      // 关闭当前数据库连接
      await _dbService.close();

      // 获取数据库路径
      final dbPath = await getDatabasesPath();
      final dbFilePath = p.join(dbPath, DatabaseService.databaseName);

      // 复制备份文件覆盖当前数据库
      await dbBackupFile.copy(dbFilePath);

      // 恢复图片（如果提供了图片备份路径）
      if (imagesBackupPath != null) {
        final zipFile = File(imagesBackupPath);
        if (await zipFile.exists()) {
          final appDir = await getApplicationDocumentsDirectory();
          final imagesDir = Directory('${appDir.path}/item_images');

          // 清空现有图片目录
          if (await imagesDir.exists()) {
            await imagesDir.delete(recursive: true);
          }
          await imagesDir.create(recursive: true);

          // 解压图片
          await _unzipFile(imagesBackupPath, imagesDir.path);
        }
      }
    } catch (e) {
      rethrow;
    }
  }

  /// 获取本地备份列表
  Future<List<BackupHistory>> getLocalBackups() async {
    return await _dbService.getBackupHistory(limit: 20);
  }

  /// 删除本地备份（同时删除数据库和图片备份）
  Future<void> deleteLocalBackup(String backupId, String? filePath) async {
    // 删除数据库备份文件
    if (filePath != null) {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }

      // 尝试删除对应的图片备份文件
      // 文件名格式: backup_2026-05-07.db -> backup_2026-05-07_images.zip
      final dir = p.dirname(filePath);
      final fileName = p.basenameWithoutExtension(filePath);
      final imagesBackupPath = p.join(dir, '${fileName}_images.zip');
      final imagesFile = File(imagesBackupPath);
      if (await imagesFile.exists()) {
        await imagesFile.delete();
      }
    }

    // 从历史记录中删除（需要在 DatabaseService 中添加方法）
    // 暂时保留历史记录
  }

  /// 清理旧备份（保留最近N个，同时清理图片备份）
  Future<void> cleanupOldBackups({int keepCount = 10}) async {
    final history = await _dbService.getBackupHistory();

    if (history.length <= keepCount) return;

    final toDelete = history.skip(keepCount);
    for (final record in toDelete) {
      if (record.filePath != null) {
        // 删除数据库备份
        final file = File(record.filePath!);
        if (await file.exists()) {
          await file.delete();
        }

        // 删除对应的图片备份
        final dir = p.dirname(record.filePath!);
        final fileName = p.basenameWithoutExtension(record.filePath!);
        final imagesBackupPath = p.join(dir, '${fileName}_images.zip');
        final imagesFile = File(imagesBackupPath);
        if (await imagesFile.exists()) {
          await imagesFile.delete();
        }
      }
    }
  }

  /// 打包目录为 ZIP 文件
  Future<void> _zipDirectory(String sourcePath, String targetPath) async {
    final archive = Archive();
    final sourceDir = Directory(sourcePath);

    if (!await sourceDir.exists()) return;

    await for (final entity in sourceDir.list(recursive: true)) {
      if (entity is File) {
        final relativePath = p.relative(entity.path, from: sourcePath);
        final bytes = await entity.readAsBytes();

        archive.addFile(ArchiveFile(
          relativePath,
          bytes.length,
          bytes,
        ));
      }
    }

    final zipBytes = ZipEncoder().encode(archive);
    await File(targetPath).writeAsBytes(zipBytes);
  }

  /// 解压 ZIP 文件到目录
  Future<void> _unzipFile(String zipPath, String targetPath) async {
    final bytes = await File(zipPath).readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);

    for (final file in archive) {
      final filePath = p.join(targetPath, file.name);

      if (file.isFile) {
        final outputFile = File(filePath);
        await outputFile.parent.create(recursive: true);
        await outputFile.writeAsBytes(file.content as List<int>);
      } else {
        await Directory(filePath).create(recursive: true);
      }
    }
  }

  /// 生成唯一ID
  String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }
}
