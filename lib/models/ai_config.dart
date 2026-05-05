import '../utils/constants.dart';

/// AI配置实体
class AIConfig {
  final String id;
  final AIProvider provider;
  final String apiKey;
  final String defaultModel;
  final String? baseUrl;        // 自定义API地址（仅自定义提供商使用）
  final String? displayName;    // 用户自定义名称
  final int timeoutSeconds;
  final bool enabled;
  final bool isDefault;         // 是否为默认配置
  final DateTime createdAt;
  final DateTime updatedAt;

  const AIConfig({
    required this.id,
    required this.provider,
    required this.apiKey,
    required this.defaultModel,
    this.baseUrl,
    this.displayName,
    this.timeoutSeconds = 30,
    this.enabled = true,
    this.isDefault = false,
    required this.createdAt,
    required this.updatedAt,
  });

  /// 默认配置
  factory AIConfig.defaultConfig(String id) {
    final now = DateTime.now();
    return AIConfig(
      id: id,
      provider: AIProvider.doubao,
      apiKey: '',
      defaultModel: 'doubao-1.5-vision-pro',
      isDefault: true,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// 从JSON创建
  factory AIConfig.fromJson(Map<String, dynamic> json) {
    // 安全解析布尔值（SQLite存储为0/1整数）
    bool parseBool(dynamic value, {bool defaultValue = true}) {
      if (value == null) return defaultValue;
      if (value is bool) return value;
      if (value is int) return value != 0;
      return defaultValue;
    }

    return AIConfig(
      id: json['id'] as String,
      provider: AIProvider.values.firstWhere(
        (e) => e.name == json['provider'],
        orElse: () => AIProvider.doubao,
      ),
      apiKey: json['api_key'] as String? ?? '',
      defaultModel: json['default_model'] as String? ?? 'doubao-1.5-vision-pro',
      baseUrl: json['base_url'] as String?,
      displayName: json['display_name'] as String?,
      timeoutSeconds: json['timeout_seconds'] as int? ?? 30,
      enabled: parseBool(json['enabled'], defaultValue: true),
      isDefault: parseBool(json['is_default'], defaultValue: false),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'provider': provider.name,
      'api_key': apiKey,
      'default_model': defaultModel,
      'base_url': baseUrl,
      'display_name': displayName,
      'timeout_seconds': timeoutSeconds,
      'enabled': enabled,
      'is_default': isDefault ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// 复制并修改
  AIConfig copyWith({
    String? id,
    AIProvider? provider,
    String? apiKey,
    String? defaultModel,
    String? baseUrl,
    String? displayName,
    int? timeoutSeconds,
    bool? enabled,
    bool? isDefault,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AIConfig(
      id: id ?? this.id,
      provider: provider ?? this.provider,
      apiKey: apiKey ?? this.apiKey,
      defaultModel: defaultModel ?? this.defaultModel,
      baseUrl: baseUrl ?? this.baseUrl,
      displayName: displayName ?? this.displayName,
      timeoutSeconds: timeoutSeconds ?? this.timeoutSeconds,
      enabled: enabled ?? this.enabled,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
