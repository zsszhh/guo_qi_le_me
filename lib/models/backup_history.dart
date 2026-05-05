/// 备份类型枚举
enum BackupType {
  local,
  webdav,
}

/// 备份状态枚举
enum BackupStatus {
  success,
  failed,
}

/// 备份历史记录实体
class BackupHistory {
  final String id;
  final BackupType backupType;
  final BackupStatus status;
  final String? filePath;
  final String? errorMessage;
  final int? fileSizeBytes;
  final DateTime backupAt;
  final DateTime createdAt;

  const BackupHistory({
    required this.id,
    required this.backupType,
    required this.status,
    this.filePath,
    this.errorMessage,
    this.fileSizeBytes,
    required this.backupAt,
    required this.createdAt,
  });

  /// 从JSON创建
  factory BackupHistory.fromJson(Map<String, dynamic> json) {
    return BackupHistory(
      id: json['id'] as String,
      backupType: BackupType.values.firstWhere(
        (e) => e.name == json['backup_type'],
        orElse: () => BackupType.local,
      ),
      status: BackupStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => BackupStatus.success,
      ),
      filePath: json['file_path'] as String?,
      errorMessage: json['error_message'] as String?,
      fileSizeBytes: json['file_size_bytes'] as int?,
      backupAt: DateTime.parse(json['backup_at'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'backup_type': backupType.name,
      'status': status.name,
      'file_path': filePath,
      'error_message': errorMessage,
      'file_size_bytes': fileSizeBytes,
      'backup_at': backupAt.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// 复制并修改
  BackupHistory copyWith({
    String? id,
    BackupType? backupType,
    BackupStatus? status,
    String? filePath,
    String? errorMessage,
    int? fileSizeBytes,
    DateTime? backupAt,
    DateTime? createdAt,
  }) {
    return BackupHistory(
      id: id ?? this.id,
      backupType: backupType ?? this.backupType,
      status: status ?? this.status,
      filePath: filePath ?? this.filePath,
      errorMessage: errorMessage ?? this.errorMessage,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      backupAt: backupAt ?? this.backupAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
