import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/item.dart';
import '../models/reminder_config.dart';
import '../models/reminder_log.dart';
import '../models/ai_learning_record.dart';
import '../models/webdav_config.dart';
import '../models/ai_config.dart';
import '../models/backup_history.dart';
import '../models/product_image.dart';
import '../models/ai_analysis_cache.dart';
import 'secure_storage_service.dart';

/// 数据库服务
class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static Database? _database;
  final SecureStorageService _secureStorage = SecureStorageService();

  /// 数据库名称
  static const String _databaseName = 'guo_qi_le_me.db';

  /// 获取数据库名称（公开）
  static String get databaseName => _databaseName;

  /// 数据库版本
  static const int _databaseVersion = 6;

  /// 表名常量
  static const String tableItems = 'items';
  static const String tableReminderConfigs = 'reminder_configs';
  static const String tableReminderLogs = 'reminder_logs';
  static const String tableAILearningRecords = 'ai_learning_records';
  static const String tableWebDAVConfigs = 'webdav_configs';
  static const String tableAIConfigs = 'ai_configs';
  static const String tableBackupHistory = 'backup_history';
  static const String tableCustomOptions = 'custom_options';
  static const String tableProductImages = 'product_images';
  static const String tableAIAnalysisCache = 'ai_analysis_cache';

  /// 获取数据库实例
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// 初始化数据库
  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _databaseName);

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// 创建数据库表
  Future<void> _onCreate(Database db, int version) async {
    // 物品表
    await db.execute('''
      CREATE TABLE $tableItems (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        category TEXT NOT NULL,
        sub_category TEXT,
        brand TEXT,
        specification TEXT,
        purchase_date TEXT NOT NULL,
        expiry_date TEXT NOT NULL,
        opened_date TEXT,
        suggested_use_date TEXT,
        use_date_source TEXT,
        is_individually_wrapped INTEGER DEFAULT 0,
        quantity INTEGER DEFAULT 1,
        unit TEXT DEFAULT '个',
        location TEXT,
        notes TEXT,
        image_url TEXT,
        status TEXT NOT NULL,
        ai_confidence REAL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // 提醒配置表
    await db.execute('''
      CREATE TABLE $tableReminderConfigs (
        id TEXT PRIMARY KEY,
        remind_3_days INTEGER DEFAULT 1,
        remind_7_days INTEGER DEFAULT 1,
        remind_14_days INTEGER DEFAULT 1,
        push_notification INTEGER DEFAULT 1,
        reminder_time TEXT DEFAULT '09:00',
        sound_enabled INTEGER DEFAULT 1,
        quiet_hours_start TEXT,
        quiet_hours_end TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // 提醒记录表
    await db.execute('''
      CREATE TABLE $tableReminderLogs (
        id TEXT PRIMARY KEY,
        item_id TEXT NOT NULL,
        reminder_type TEXT NOT NULL,
        status TEXT NOT NULL,
        notified_at TEXT NOT NULL,
        read_at TEXT,
        actioned_at TEXT,
        FOREIGN KEY (item_id) REFERENCES $tableItems (id) ON DELETE CASCADE
      )
    ''');

    // AI学习记录表
    await db.execute('''
      CREATE TABLE $tableAILearningRecords (
        id TEXT PRIMARY KEY,
        item_name TEXT NOT NULL,
        category TEXT NOT NULL,
        sub_category TEXT,
        brand TEXT,
        typical_expiry_days INTEGER NOT NULL,
        usage_count INTEGER DEFAULT 1,
        last_used_at TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    // WebDAV配置表
    await db.execute('''
      CREATE TABLE $tableWebDAVConfigs (
        id TEXT PRIMARY KEY,
        server_url TEXT NOT NULL,
        username TEXT NOT NULL,
        password TEXT NOT NULL,
        remote_path TEXT DEFAULT '/guo_qi_le_me',
        sync_interval INTEGER DEFAULT 30,
        auto_sync INTEGER DEFAULT 0,
        enabled INTEGER DEFAULT 0,
        last_sync_at TEXT,
        sync_status TEXT DEFAULT 'idle',
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // AI配置表
    await db.execute('''
      CREATE TABLE $tableAIConfigs (
        id TEXT PRIMARY KEY,
        provider TEXT NOT NULL,
        api_key TEXT NOT NULL,
        default_model TEXT NOT NULL,
        base_url TEXT,
        display_name TEXT,
        timeout_seconds INTEGER DEFAULT 30,
        enabled INTEGER DEFAULT 1,
        is_default INTEGER DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // 自定义选项表（存放位置、单位、子分类等）
    await db.execute('''
      CREATE TABLE $tableCustomOptions (
        id TEXT PRIMARY KEY,
        option_type TEXT NOT NULL,
        category TEXT,
        value TEXT NOT NULL,
        usage_count INTEGER DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // 备份历史表
    await db.execute('''
      CREATE TABLE $tableBackupHistory (
        id TEXT PRIMARY KEY,
        backup_type TEXT NOT NULL,
        status TEXT NOT NULL,
        file_path TEXT,
        error_message TEXT,
        file_size_bytes INTEGER,
        backup_at TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    // 产品图片表
    await db.execute('''
      CREATE TABLE $tableProductImages (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        image_path TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    // 创建索引
    await db.execute('CREATE INDEX idx_items_expiry_date ON $tableItems (expiry_date)');
    await db.execute('CREATE INDEX idx_items_status ON $tableItems (status)');
    await db.execute('CREATE INDEX idx_items_category ON $tableItems (category)');
    await db.execute('CREATE INDEX idx_reminder_logs_item_id ON $tableReminderLogs (item_id)');
    await db.execute('CREATE INDEX idx_ai_learning_item_name ON $tableAILearningRecords (item_name)');
    await db.execute('CREATE INDEX idx_product_images_name ON $tableProductImages (name)');

    // AI分析缓存表
    await db.execute('''
      CREATE TABLE $tableAIAnalysisCache (
        id TEXT PRIMARY KEY,
        cache_key TEXT NOT NULL UNIQUE,
        analysis_text TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    // 创建AI分析缓存索引
    await db.execute('CREATE INDEX idx_ai_analysis_cache_key ON $tableAIAnalysisCache (cache_key)');
  }

  /// 数据库升级
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // 版本1到版本2：添加AI配置新字段和自定义选项表
    if (oldVersion < 2) {
      // 为AI配置表添加新字段
      await db.execute('ALTER TABLE $tableAIConfigs ADD COLUMN base_url TEXT');
      await db.execute('ALTER TABLE $tableAIConfigs ADD COLUMN display_name TEXT');

      // 创建自定义选项表
      await db.execute('''
        CREATE TABLE IF NOT EXISTS $tableCustomOptions (
          id TEXT PRIMARY KEY,
          option_type TEXT NOT NULL,
          category TEXT,
          value TEXT NOT NULL,
          usage_count INTEGER DEFAULT 0,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL
        )
      ''');
    }

    // 版本2到版本3：添加产品图片表
    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS $tableProductImages (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          image_path TEXT NOT NULL,
          created_at TEXT NOT NULL
        )
      ''');

      // 创建索引
      await db.execute('CREATE INDEX IF NOT EXISTS idx_product_images_name ON $tableProductImages (name)');
    }

    // 版本3到版本4：添加 is_default 字段支持多配置
    if (oldVersion < 4) {
      await db.execute('ALTER TABLE $tableAIConfigs ADD COLUMN is_default INTEGER DEFAULT 0');
      // 将现有配置设为默认
      await db.execute('UPDATE $tableAIConfigs SET is_default = 1 WHERE enabled = 1');
    }

    // 版本4到版本5：添加AI分析缓存表
    if (oldVersion < 5) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS $tableAIAnalysisCache (
          id TEXT PRIMARY KEY,
          cache_key TEXT NOT NULL UNIQUE,
          analysis_text TEXT NOT NULL,
          created_at TEXT NOT NULL
        )
      ''');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_ai_analysis_cache_key ON $tableAIAnalysisCache (cache_key)');
    }

    // 版本5到版本6：添加开封保质期相关字段
    if (oldVersion < 6) {
      try {
        await db.transaction((txn) async {
          await txn.execute('ALTER TABLE $tableItems ADD COLUMN suggested_use_date TEXT');
          await txn.execute('ALTER TABLE $tableItems ADD COLUMN use_date_source TEXT');
          await txn.execute('ALTER TABLE $tableItems ADD COLUMN is_individually_wrapped INTEGER DEFAULT 0');
        });
      } catch (e) {
        // 字段可能已存在（迁移重试场景），忽略错误
        debugPrint('版本6迁移警告: $e');
      }
    }
  }

  // ==================== 物品操作 ====================

  /// 插入物品
  Future<void> insertItem(Item item) async {
    final db = await database;
    await db.insert(
      tableItems,
      item.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// 批量插入物品
  Future<void> insertItems(List<Item> items) async {
    final db = await database;
    final batch = db.batch();
    for (final item in items) {
      batch.insert(
        tableItems,
        item.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  /// 获取所有物品
  Future<List<Item>> getAllItems() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableItems,
      orderBy: 'expiry_date ASC',
    );
    return maps.map((map) => Item.fromJson(map)).toList();
  }

  /// 根据ID获取物品
  Future<Item?> getItemById(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableItems,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return Item.fromJson(maps.first);
  }

  /// 根据状态获取物品
  Future<List<Item>> getItemsByStatus(String status) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableItems,
      where: 'status = ?',
      whereArgs: [status],
      orderBy: 'expiry_date ASC',
    );
    return maps.map((map) => Item.fromJson(map)).toList();
  }

  /// 根据分类获取物品
  Future<List<Item>> getItemsByCategory(String category) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableItems,
      where: 'category = ?',
      whereArgs: [category],
      orderBy: 'expiry_date ASC',
    );
    return maps.map((map) => Item.fromJson(map)).toList();
  }

  /// 搜索物品（转义特殊字符防止意外匹配）
  Future<List<Item>> searchItems(String keyword) async {
    final db = await database;
    final escapedKeyword = _escapeLikePattern(keyword);
    final List<Map<String, dynamic>> maps = await db.query(
      tableItems,
      where: 'name LIKE ? ESCAPE "\\" OR brand LIKE ? ESCAPE "\\" OR location LIKE ? ESCAPE "\\"',
      whereArgs: ['%$escapedKeyword%', '%$escapedKeyword%', '%$escapedKeyword%'],
      orderBy: 'expiry_date ASC',
    );
    return maps.map((map) => Item.fromJson(map)).toList();
  }

  /// 更新物品
  Future<void> updateItem(Item item) async {
    final db = await database;
    await db.update(
      tableItems,
      item.toJson(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  /// 删除物品
  Future<void> deleteItem(String id) async {
    final db = await database;
    await db.delete(
      tableItems,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// 更新物品数量
  Future<void> updateItemQuantity(String id, int quantity) async {
    final db = await database;
    await db.update(
      tableItems,
      {
        'quantity': quantity,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// 批量删除物品
  Future<void> deleteItems(List<String> ids) async {
    final db = await database;
    final batch = db.batch();
    for (final id in ids) {
      batch.delete(
        tableItems,
        where: 'id = ?',
        whereArgs: [id],
      );
    }
    await batch.commit(noResult: true);
  }

  /// 批量更新物品状态
  Future<void> updateItemsStatus(List<String> ids, String status) async {
    final db = await database;
    final batch = db.batch();
    final now = DateTime.now().toIso8601String();
    for (final id in ids) {
      batch.update(
        tableItems,
        {
          'status': status,
          'updated_at': now,
        },
        where: 'id = ?',
        whereArgs: [id],
      );
    }
    await batch.commit(noResult: true);
  }

  /// 获取物品数量
  Future<int> getItemCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM $tableItems');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// 获取最近添加的物品
  Future<List<Item>> getRecentItems({int limit = 5}) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableItems,
      orderBy: 'created_at DESC',
      limit: limit,
    );
    return maps.map((map) => Item.fromJson(map)).toList();
  }

  /// 按状态统计物品数量
  Future<Map<String, int>> getItemCountByStatus() async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT status, COUNT(*) as count
      FROM $tableItems
      GROUP BY status
    ''');
    return Map.fromEntries(
      result.map((row) => MapEntry(row['status'] as String, row['count'] as int)),
    );
  }

  // ==================== 提醒配置操作 ====================

  /// 获取提醒配置（单例）
  Future<ReminderConfig?> getReminderConfig() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(tableReminderConfigs);
    if (maps.isEmpty) return null;
    return ReminderConfig.fromJson(maps.first);
  }

  /// 保存提醒配置
  Future<void> saveReminderConfig(ReminderConfig config) async {
    final db = await database;
    await db.insert(
      tableReminderConfigs,
      config.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // ==================== 提醒记录操作 ====================

  /// 插入提醒记录
  Future<void> insertReminderLog(ReminderLog log) async {
    final db = await database;
    await db.insert(
      tableReminderLogs,
      log.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// 获取待处理提醒
  Future<List<ReminderLog>> getPendingReminders() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableReminderLogs,
      where: 'status = ?',
      whereArgs: ['pending'],
      orderBy: 'notified_at DESC',
    );
    return maps.map((map) => ReminderLog.fromJson(map)).toList();
  }

  /// 获取物品的提醒记录
  Future<List<ReminderLog>> getReminderLogsByItemId(String itemId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableReminderLogs,
      where: 'item_id = ?',
      whereArgs: [itemId],
      orderBy: 'notified_at DESC',
    );
    return maps.map((map) => ReminderLog.fromJson(map)).toList();
  }

  /// 更新提醒记录
  Future<void> updateReminderLog(ReminderLog log) async {
    final db = await database;
    await db.update(
      tableReminderLogs,
      log.toJson(),
      where: 'id = ?',
      whereArgs: [log.id],
    );
  }

  // ==================== AI学习记录操作 ====================

  /// 插入或更新AI学习记录
  Future<void> saveAILearningRecord(AILearningRecord record) async {
    final db = await database;

    // 检查是否存在相同名称的记录
    final existing = await db.query(
      tableAILearningRecords,
      where: 'item_name = ?',
      whereArgs: [record.itemName],
    );

    if (existing.isNotEmpty) {
      // 更新使用次数和最后使用时间
      final existingRecord = AILearningRecord.fromJson(existing.first);
      await db.update(
        tableAILearningRecords,
        {
          'usage_count': existingRecord.usageCount + 1,
          'last_used_at': record.lastUsedAt.toIso8601String(),
          'typical_expiry_days': record.typicalExpiryDays,
        },
        where: 'id = ?',
        whereArgs: [existingRecord.id],
      );
    } else {
      await db.insert(
        tableAILearningRecords,
        record.toJson(),
      );
    }
  }

  /// 获取AI学习记录
  Future<List<AILearningRecord>> getAILearningRecords() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableAILearningRecords,
      orderBy: 'usage_count DESC, last_used_at DESC',
    );
    return maps.map((map) => AILearningRecord.fromJson(map)).toList();
  }

  /// 根据名称搜索AI学习记录
  Future<List<AILearningRecord>> searchAILearningRecords(String keyword) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableAILearningRecords,
      where: 'item_name LIKE ?',
      whereArgs: ['%$keyword%'],
      orderBy: 'usage_count DESC',
      limit: 10,
    );
    return maps.map((map) => AILearningRecord.fromJson(map)).toList();
  }

  // ==================== WebDAV配置操作 ====================

  /// 获取WebDAV配置（单例）
  Future<WebDAVConfig?> getWebDAVConfig() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(tableWebDAVConfigs);
    if (maps.isEmpty) return null;
    return WebDAVConfig.fromJson(maps.first);
  }

  /// 保存WebDAV配置（密码存入安全存储，数据库不保留明文）
  Future<void> saveWebDAVConfig(WebDAVConfig config) async {
    final db = await database;

    // 将密码存入安全存储
    if (config.password.isNotEmpty) {
      await _secureStorage.saveWebDAVPassword(config.password);
    }

    // 数据库中不存储密码，使用空字符串占位
    final secureConfig = config.copyWith(password: '');
    await db.insert(
      tableWebDAVConfigs,
      secureConfig.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // ==================== AI配置操作 ====================

  /// 获取所有AI配置列表，按 is_default DESC, updated_at DESC 排序
  Future<List<AIConfig>> getAllAIConfigs() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableAIConfigs,
      orderBy: 'is_default DESC, updated_at DESC',
    );
    return maps.map((map) => AIConfig.fromJson(map)).toList();
  }

  /// 获取AI配置（优先返回 is_default=1 的配置，否则返回第一个配置）
  Future<AIConfig?> getAIConfig() async {
    final db = await database;
    // 优先获取默认配置
    final List<Map<String, dynamic>> defaultMaps = await db.query(
      tableAIConfigs,
      where: 'is_default = ?',
      whereArgs: [1],
      limit: 1,
    );
    if (defaultMaps.isNotEmpty) {
      return AIConfig.fromJson(defaultMaps.first);
    }
    // 如果没有默认配置，返回第一个配置
    final List<Map<String, dynamic>> maps = await db.query(
      tableAIConfigs,
      orderBy: 'updated_at DESC',
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return AIConfig.fromJson(maps.first);
  }

  /// 根据ID获取AI配置
  Future<AIConfig?> getAIConfigById(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableAIConfigs,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return AIConfig.fromJson(maps.first);
  }

  /// 保存AI配置（API Key存入安全存储，数据库不保留明文）
  Future<void> saveAIConfig(AIConfig config) async {
    final db = await database;

    // 将API Key存入安全存储
    if (config.apiKey.isNotEmpty) {
      await _secureStorage.saveApiKey(config.id, config.apiKey);
    }

    // 数据库中不存储API Key，使用空字符串占位
    final secureConfig = config.copyWith(apiKey: '');
    await db.insert(
      tableAIConfigs,
      secureConfig.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// 设置默认AI配置
  Future<void> setDefaultAIConfig(String id) async {
    final db = await database;
    await db.transaction((txn) async {
      // 先清除所有默认标记
      await txn.update(
        tableAIConfigs,
        {'is_default': 0},
      );
      // 设置指定配置为默认
      await txn.update(
        tableAIConfigs,
        {'is_default': 1, 'updated_at': DateTime.now().toIso8601String()},
        where: 'id = ?',
        whereArgs: [id],
      );
    });
  }

  /// 删除AI配置（处理默认配置切换逻辑，清理安全存储）
  Future<void> deleteAIConfig(String id) async {
    final db = await database;

    // 检查是否为默认配置
    final config = await getAIConfigById(id);
    if (config == null) return;

    final isDefault = config.isDefault;

    // 清理安全存储中的API Key
    await _secureStorage.deleteApiKey(id);

    await db.transaction((txn) async {
      // 删除配置
      await txn.delete(
        tableAIConfigs,
        where: 'id = ?',
        whereArgs: [id],
      );

      // 如果删除的是默认配置，将第一个配置设为默认
      if (isDefault) {
        final remaining = await txn.query(
          tableAIConfigs,
          orderBy: 'updated_at DESC',
          limit: 1,
        );
        if (remaining.isNotEmpty) {
          await txn.update(
            tableAIConfigs,
            {'is_default': 1},
            where: 'id = ?',
            whereArgs: [remaining.first['id']],
          );
        }
      }
    });
  }

  /// 复制AI配置（同时复制API Key到安全存储）
  Future<AIConfig> duplicateAIConfig(String id) async {
    final db = await database;
    final original = await getAIConfigById(id);
    if (original == null) {
      throw Exception('AI配置不存在: $id');
    }

    final now = DateTime.now();
    final newId = '${id}_copy_${now.millisecondsSinceEpoch}';
    final displayName = original.displayName != null
        ? '${original.displayName} (副本)'
        : null;

    // 从安全存储获取原始API Key并复制到新ID
    final originalApiKey = await _secureStorage.getApiKey(id);
    if (originalApiKey != null && originalApiKey.isNotEmpty) {
      await _secureStorage.saveApiKey(newId, originalApiKey);
    }

    final duplicated = original.copyWith(
      id: newId,
      displayName: displayName,
      isDefault: false,
      createdAt: now,
      updatedAt: now,
      apiKey: '', // 数据库不存储API Key
    );

    await db.insert(
      tableAIConfigs,
      duplicated.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    return duplicated;
  }

  /// 更新AI配置的 enabled 状态
  Future<void> updateAIConfigEnabled(String id, bool enabled) async {
    final db = await database;
    await db.update(
      tableAIConfigs,
      {
        'enabled': enabled ? 1 : 0,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ==================== 备份历史操作 ====================

  /// 插入备份历史
  Future<void> insertBackupHistory(BackupHistory history) async {
    final db = await database;
    await db.insert(
      tableBackupHistory,
      history.toJson(),
    );
  }

  /// 获取备份历史
  Future<List<BackupHistory>> getBackupHistory({int? limit}) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableBackupHistory,
      orderBy: 'backup_at DESC',
      limit: limit,
    );
    return maps.map((map) => BackupHistory.fromJson(map)).toList();
  }

  // ==================== 数据导入导出 ====================

  /// 清空所有数据
  Future<void> clearAllData() async {
    final db = await database;
    await db.delete(tableItems);
    await db.delete(tableReminderConfigs);
    await db.delete(tableReminderLogs);
    await db.delete(tableAILearningRecords);
    await db.delete(tableWebDAVConfigs);
    await db.delete(tableAIConfigs);
    await db.delete(tableBackupHistory);
    await db.delete(tableCustomOptions);
  }

  // ==================== 产品图片操作 ====================

  /// 插入产品图片
  Future<void> insertProductImage(ProductImage productImage) async {
    final db = await database;
    await db.insert(
      tableProductImages,
      productImage.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// 根据名称搜索产品图片（模糊匹配，转义特殊字符）
  Future<List<ProductImage>> searchProductImages(String keyword) async {
    final db = await database;
    final escapedKeyword = _escapeLikePattern(keyword);
    final List<Map<String, dynamic>> maps = await db.query(
      tableProductImages,
      where: 'name LIKE ? ESCAPE "\\"',
      whereArgs: ['%$escapedKeyword%'],
      orderBy: 'created_at DESC',
      limit: 10,
    );
    return maps.map((map) => ProductImage.fromJson(map)).toList();
  }

  /// 检查产品名是否已有图片
  Future<bool> hasProductImage(String name) async {
    final db = await database;
    final result = await db.query(
      tableProductImages,
      where: 'name = ?',
      whereArgs: [name],
      limit: 1,
    );
    return result.isNotEmpty;
  }

  /// 获取所有产品图片
  Future<List<ProductImage>> getAllProductImages() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableProductImages,
      orderBy: 'name ASC',
    );
    return maps.map((map) => ProductImage.fromJson(map)).toList();
  }

  /// 删除产品图片
  Future<void> deleteProductImage(String id) async {
    final db = await database;
    await db.delete(
      tableProductImages,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ==================== 相似物品搜索 ====================

  /// 搜索相似物品（用于历史数据复用，转义特殊字符）
  Future<List<Item>> searchSimilarItems(String name) async {
    final db = await database;
    final escapedName = _escapeLikePattern(name);
    final List<Map<String, dynamic>> maps = await db.query(
      tableItems,
      where: 'name LIKE ? ESCAPE "\\"',
      whereArgs: ['%$escapedName%'],
      orderBy: 'updated_at DESC',
      limit: 10,
    );
    return maps.map((map) => Item.fromJson(map)).toList();
  }

  /// 转义 SQL LIKE 查询中的特殊字符
  String _escapeLikePattern(String pattern) {
    return pattern
        .replaceAll('\\', '\\\\')
        .replaceAll('%', '\\%')
        .replaceAll('_', '\\_');
  }

  // ==================== AI分析缓存操作 ====================

  /// 获取AI分析缓存
  Future<AIAnalysisCache?> getAIAnalysisCache(String cacheKey) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableAIAnalysisCache,
      where: 'cache_key = ?',
      whereArgs: [cacheKey],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return AIAnalysisCache.fromJson(maps.first);
  }

  /// 保存AI分析缓存
  Future<void> saveAIAnalysisCache(AIAnalysisCache cache) async {
    final db = await database;
    await db.insert(
      tableAIAnalysisCache,
      cache.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// 清除过期的AI分析缓存（超过30天）
  Future<void> clearExpiredAIAnalysisCache() async {
    final db = await database;
    final expiryDate = DateTime.now().subtract(const Duration(days: 30));
    await db.delete(
      tableAIAnalysisCache,
      where: 'created_at < ?',
      whereArgs: [expiryDate.toIso8601String()],
    );
  }

  /// 关闭数据库
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}
