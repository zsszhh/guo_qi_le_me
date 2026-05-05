/// 同步状态枚举
enum SyncStatus {
  idle,
  syncing,
  error,
}

/// WebDAV配置实体
class WebDAVConfig {
  final String id;
  final String serverUrl;
  final String username;
  final String password;
  final String remotePath;
  final int syncInterval;
  final bool autoSync;
  final bool enabled;
  final DateTime? lastSyncAt;
  final SyncStatus syncStatus;
  final DateTime createdAt;
  final DateTime updatedAt;

  const WebDAVConfig({
    required this.id,
    required this.serverUrl,
    required this.username,
    required this.password,
    this.remotePath = '/guo_qi_le_me',
    this.syncInterval = 30,
    this.autoSync = false,
    this.enabled = false,
    this.lastSyncAt,
    this.syncStatus = SyncStatus.idle,
    required this.createdAt,
    required this.updatedAt,
  });

  /// 默认配置
  factory WebDAVConfig.defaultConfig(String id) {
    final now = DateTime.now();
    return WebDAVConfig(
      id: id,
      serverUrl: '',
      username: '',
      password: '',
      createdAt: now,
      updatedAt: now,
    );
  }

  /// 从JSON创建
  factory WebDAVConfig.fromJson(Map<String, dynamic> json) {
    // 安全解析布尔值（SQLite存储为0/1整数）
    bool parseBool(dynamic value, {bool defaultValue = false}) {
      if (value == null) return defaultValue;
      if (value is bool) return value;
      if (value is int) return value != 0;
      return defaultValue;
    }

    return WebDAVConfig(
      id: json['id'] as String,
      serverUrl: json['server_url'] as String? ?? '',
      username: json['username'] as String? ?? '',
      password: json['password'] as String? ?? '',
      remotePath: json['remote_path'] as String? ?? '/guo_qi_le_me',
      syncInterval: json['sync_interval'] as int? ?? 30,
      autoSync: parseBool(json['auto_sync']),
      enabled: parseBool(json['enabled']),
      lastSyncAt: json['last_sync_at'] != null
          ? DateTime.parse(json['last_sync_at'] as String)
          : null,
      syncStatus: SyncStatus.values.firstWhere(
        (e) => e.name == json['sync_status'],
        orElse: () => SyncStatus.idle,
      ),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'server_url': serverUrl,
      'username': username,
      'password': password,
      'remote_path': remotePath,
      'sync_interval': syncInterval,
      'auto_sync': autoSync,
      'enabled': enabled,
      'last_sync_at': lastSyncAt?.toIso8601String(),
      'sync_status': syncStatus.name,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// 复制并修改
  WebDAVConfig copyWith({
    String? id,
    String? serverUrl,
    String? username,
    String? password,
    String? remotePath,
    int? syncInterval,
    bool? autoSync,
    bool? enabled,
    DateTime? lastSyncAt,
    SyncStatus? syncStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return WebDAVConfig(
      id: id ?? this.id,
      serverUrl: serverUrl ?? this.serverUrl,
      username: username ?? this.username,
      password: password ?? this.password,
      remotePath: remotePath ?? this.remotePath,
      syncInterval: syncInterval ?? this.syncInterval,
      autoSync: autoSync ?? this.autoSync,
      enabled: enabled ?? this.enabled,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
      syncStatus: syncStatus ?? this.syncStatus,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
