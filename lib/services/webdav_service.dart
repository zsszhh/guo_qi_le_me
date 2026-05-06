import 'dart:io';
import 'package:archive/archive.dart';
import 'package:archive/archive_io.dart';
import 'package:webdav_client/webdav_client.dart' as webdav;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import '../models/webdav_config.dart';
import '../models/backup_history.dart';
import '../services/database_service.dart';
import '../utils/constants.dart';
import '../utils/date_utils.dart' as app_date_utils;
import 'secure_storage_service.dart';

/// WebDAV 连接测试结果
class WebDAVConnectionResult {
  final bool success;
  final String? errorMessage;

  const WebDAVConnectionResult({
    required this.success,
    this.errorMessage,
  });
}

/// WebDAV同步服务
class WebDAVService {
  static final WebDAVService _instance = WebDAVService._internal();
  factory WebDAVService() => _instance;
  WebDAVService._internal();

  final DatabaseService _dbService = DatabaseService();
  final SecureStorageService _secureStorage = SecureStorageService();
  webdav.Client? _client;

  /// 获取安全的密码（优先从安全存储获取）
  Future<String> _getSecurePassword(WebDAVConfig config) async {
    // 优先从安全存储获取
    final securePassword = await _secureStorage.getWebDAVPassword();
    if (securePassword != null && securePassword.isNotEmpty) {
      return securePassword;
    }
    // 降级使用配置中的密码（向后兼容）
    return config.password;
  }

  /// 初始化WebDAV客户端
  Future<void> _initClient(WebDAVConfig config) async {
    final password = await _getSecurePassword(config);
    _client = webdav.newClient(
      config.serverUrl,
      user: config.username,
      password: password,
      debug: false,
    );

    _client!.setHeaders({'accept-charset': 'utf-8'});
    _client!.setConnectTimeout(30000);
    _client!.setSendTimeout(30000);
    _client!.setReceiveTimeout(30000);
  }

  /// 测试连接
  Future<WebDAVConnectionResult> testConnection(WebDAVConfig config) async {
    try {
      await _initClient(config);
      await _client!.ping();
      return const WebDAVConnectionResult(success: true);
    } catch (e) {
      return WebDAVConnectionResult(success: false, errorMessage: e.toString());
    }
  }

  /// 上传数据库到WebDAV
  Future<BackupHistory> uploadToWebDAV(WebDAVConfig config) async {
    final now = DateTime.now();
    final backupId = DateTime.now().millisecondsSinceEpoch.toString();

    try {
      await _initClient(config);

      // 确保远程目录存在
      await _ensureRemoteDirectory(config.remotePath);

      // 获取数据库文件
      final dbPath = await getDatabasesPath();
      final dbFile = File(p.join(dbPath, AppConstants.databaseName));

      if (!await dbFile.exists()) {
        throw Exception('数据库文件不存在');
      }

      // 生成远程文件名
      final remoteFileName = 'backup_${app_date_utils.DateUtils.formatDateForFileName(now)}.db';
      final remoteFilePath = '${config.remotePath}/$remoteFileName';

      // 上传文件
      await _client!.writeFromFile(
        dbFile.path,
        remoteFilePath,
        onProgress: (count, total) {
          // 上传进度
        },
      );

      // 记录备份历史
      final history = BackupHistory(
        id: backupId,
        backupType: BackupType.webdav,
        status: BackupStatus.success,
        filePath: remoteFilePath,
        fileSizeBytes: await dbFile.length(),
        backupAt: now,
        createdAt: now,
      );

      await _dbService.insertBackupHistory(history);
      return history;
    } catch (e) {
      // 记录失败历史
      final history = BackupHistory(
        id: backupId,
        backupType: BackupType.webdav,
        status: BackupStatus.failed,
        errorMessage: e.toString(),
        backupAt: now,
        createdAt: now,
      );

      await _dbService.insertBackupHistory(history);
      rethrow;
    }
  }

  /// 从WebDAV下载数据库
  Future<void> downloadFromWebDAV(WebDAVConfig config, String remoteFilePath) async {
    try {
      await _initClient(config);

      // 关闭当前数据库连接
      await _dbService.close();

      // 获取本地数据库路径
      final dbPath = await getDatabasesPath();
      final localFilePath = p.join(dbPath, AppConstants.databaseName);

      // 下载文件
      await _client!.read2File(
        remoteFilePath,
        localFilePath,
        onProgress: (count, total) {
          // 下载进度
        },
      );
    } catch (e) {
      rethrow;
    }
  }

  /// 获取远程备份列表
  Future<List<RemoteBackupInfo>> listRemoteBackups(WebDAVConfig config) async {
    try {
      await _initClient(config);

      final files = await _client!.readDir(config.remotePath);

      return files
          .where((file) => file.path != null && file.path!.endsWith('.db'))
          .map((file) => RemoteBackupInfo(
                path: file.path!,
                name: p.basename(file.path!),
                size: file.size ?? 0,
                modifiedTime: file.mTime ?? DateTime.now(),
              ))
          .toList()
        ..sort((a, b) => b.modifiedTime.compareTo(a.modifiedTime));
    } catch (e) {
      rethrow;
    }
  }

  /// 删除远程备份
  Future<void> deleteRemoteBackup(WebDAVConfig config, String remoteFilePath) async {
    try {
      await _initClient(config);
      await _client!.remove(remoteFilePath);
    } catch (e) {
      rethrow;
    }
  }

  /// 确保远程目录存在
  Future<void> _ensureRemoteDirectory(String path) async {
    try {
      await _client!.readDir(path);
    } catch (e) {
      // 目录不存在，创建它
      await _client!.mkdir(path);
    }
  }

  /// 上传备份（包含数据库和图片）
  Future<BackupHistory> uploadBackupWithImages(WebDAVConfig config) async {
    final now = DateTime.now();
    final backupId = DateTime.now().millisecondsSinceEpoch.toString();

    try {
      await _initClient(config);

      // 确保远程目录存在
      await _ensureRemoteDirectory(config.remotePath);

      // 1. 上传数据库文件
      final dbPath = await getDatabasesPath();
      final dbFile = File(p.join(dbPath, AppConstants.databaseName));

      if (!await dbFile.exists()) {
        throw Exception('数据库文件不存在');
      }

      final dateStr = app_date_utils.DateUtils.formatDateForFileName(now);
      final dbFileName = 'backup_$dateStr.db';
      final dbRemotePath = '${config.remotePath}/$dbFileName';

      await _client!.writeFromFile(
        dbFile.path,
        dbRemotePath,
        onProgress: (count, total) {},
      );

      // 2. 打包并上传图片目录
      final appDir = await getApplicationDocumentsDirectory();
      final imagesDir = Directory('${appDir.path}/item_images');

      String? imagesRemotePath;
      int totalSize = await dbFile.length();

      if (await imagesDir.exists()) {
        final zipFileName = 'backup_${dateStr}_images.zip';
        final zipLocalPath = '${appDir.path}/$zipFileName';

        // 创建 ZIP 文件
        await _zipDirectory(imagesDir.path, zipLocalPath);

        final zipFile = File(zipLocalPath);
        if (await zipFile.exists()) {
          imagesRemotePath = '${config.remotePath}/$zipFileName';

          await _client!.writeFromFile(
            zipLocalPath,
            imagesRemotePath,
            onProgress: (count, total) {},
          );

          totalSize += await zipFile.length();

          // 删除临时 ZIP 文件
          await zipFile.delete();
        }
      }

      // 记录备份历史
      final history = BackupHistory(
        id: backupId,
        backupType: BackupType.webdav,
        status: BackupStatus.success,
        filePath: dbRemotePath,
        fileSizeBytes: totalSize,
        backupAt: now,
        createdAt: now,
      );

      await _dbService.insertBackupHistory(history);
      return history;
    } catch (e) {
      final history = BackupHistory(
        id: backupId,
        backupType: BackupType.webdav,
        status: BackupStatus.failed,
        errorMessage: e.toString(),
        backupAt: now,
        createdAt: now,
      );

      await _dbService.insertBackupHistory(history);
      rethrow;
    }
  }

  /// 从 WebDAV 恢复（包含数据库和图片）
  Future<void> downloadAndRestoreWithImages(
    WebDAVConfig config,
    String dbRemotePath,
    String? imagesRemotePath,
  ) async {
    try {
      await _initClient(config);

      // 1. 下载并恢复数据库
      await _dbService.close();

      final dbPath = await getDatabasesPath();
      final localDbPath = p.join(dbPath, AppConstants.databaseName);

      await _client!.read2File(
        dbRemotePath,
        localDbPath,
        onProgress: (count, total) {},
      );

      // 2. 下载并解压图片（如果有）
      if (imagesRemotePath != null) {
        final appDir = await getApplicationDocumentsDirectory();
        final zipLocalPath = '${appDir.path}/restore_images.zip';

        await _client!.read2File(
          imagesRemotePath,
          zipLocalPath,
          onProgress: (count, total) {},
        );

        // 解压到 item_images 目录
        final imagesDir = Directory('${appDir.path}/item_images');
        if (await imagesDir.exists()) {
          await imagesDir.delete(recursive: true);
        }
        await imagesDir.create(recursive: true);

        await _unzipFile(zipLocalPath, imagesDir.path);

        // 删除临时 ZIP 文件
        final zipFile = File(zipLocalPath);
        if (await zipFile.exists()) {
          await zipFile.delete();
        }
      }
    } catch (e) {
      rethrow;
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
}

/// 远程备份信息
class RemoteBackupInfo {
  final String path;
  final String name;
  final int size;
  final DateTime modifiedTime;

  const RemoteBackupInfo({
    required this.path,
    required this.name,
    required this.size,
    required this.modifiedTime,
  });
}
