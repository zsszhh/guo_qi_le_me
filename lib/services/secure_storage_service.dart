import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// 安全存储服务
/// 用于加密存储敏感信息（API Key、密码等）
class SecureStorageService {
  static final SecureStorageService _instance = SecureStorageService._internal();
  factory SecureStorageService() => _instance;
  SecureStorageService._internal();

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      // encryptedSharedPreferences 已弃用，使用默认加密方式
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  /// API Key 存储前缀
  static const String _apiKeyPrefix = 'ai_api_key_';

  /// WebDAV 密码存储键
  static const String _webdavPasswordKey = 'webdav_password';

  /// 保存 AI API Key
  Future<void> saveApiKey(String configId, String apiKey) async {
    await _storage.write(key: '$_apiKeyPrefix$configId', value: apiKey);
  }

  /// 读取 AI API Key
  Future<String?> getApiKey(String configId) async {
    return await _storage.read(key: '$_apiKeyPrefix$configId');
  }

  /// 删除 AI API Key
  Future<void> deleteApiKey(String configId) async {
    await _storage.delete(key: '$_apiKeyPrefix$configId');
  }

  /// 保存 WebDAV 密码
  Future<void> saveWebDAVPassword(String password) async {
    await _storage.write(key: _webdavPasswordKey, value: password);
  }

  /// 读取 WebDAV 密码
  Future<String?> getWebDAVPassword() async {
    return await _storage.read(key: _webdavPasswordKey);
  }

  /// 删除 WebDAV 密码
  Future<void> deleteWebDAVPassword() async {
    await _storage.delete(key: _webdavPasswordKey);
  }

  /// 清除所有安全存储数据
  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
