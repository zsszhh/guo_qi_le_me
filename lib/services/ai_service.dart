import 'dart:convert';
import 'package:dio/dio.dart';
import '../models/ai_config.dart';
import '../utils/constants.dart';
import 'secure_storage_service.dart';

/// AI识别结果
class AIRecognitionResult {
  final String name;
  final String category;      // 改为字符串支持自定义分类
  final String? subCategory;
  final String? brand;
  final String? specification;
  final DateTime? purchaseDate;
  final DateTime expiryDate;
  final double confidence;
  final String? rawResponse;

  const AIRecognitionResult({
    required this.name,
    required this.category,
    this.subCategory,
    this.brand,
    this.specification,
    this.purchaseDate,
    required this.expiryDate,
    required this.confidence,
    this.rawResponse,
  });
}

/// 连接测试结果
class ConnectionTestResult {
  final bool success;
  final String? errorMessage;

  const ConnectionTestResult({
    required this.success,
    this.errorMessage,
  });
}

/// AI服务
class AIService {
  static final AIService _instance = AIService._internal();
  factory AIService() => _instance;
  AIService._internal();

  final Dio _dio = Dio();
  final SecureStorageService _secureStorage = SecureStorageService();

  /// 豆包API基础URL
  static const String _doubaoBaseUrl = 'https://ark.cn-beijing.volces.com/api/v3';

  /// 获取安全的API Key（优先从安全存储获取）
  Future<String> _getSecureApiKey(AIConfig config) async {
    // 优先从安全存储获取
    final secureKey = await _secureStorage.getApiKey(config.id);
    if (secureKey != null && secureKey.isNotEmpty) {
      return secureKey;
    }
    // 降级使用配置中的Key（向后兼容）
    return config.apiKey;
  }

  /// 获取API基础URL
  String _getBaseUrl(AIConfig config) {
    // 自定义提供商使用用户配置的URL
    if (config.provider == AIProvider.custom && config.baseUrl != null) {
      return config.baseUrl!.replaceAll(RegExp(r'/+$'), ''); // 移除末尾斜杠
    }
    // 豆包使用预设URL
    return _doubaoBaseUrl;
  }

  /// 测试AI配置连接
  Future<ConnectionTestResult> testConnection(AIConfig config) async {
    try {
      final baseUrl = _getBaseUrl(config);
      final apiKey = await _getSecureApiKey(config);

      if (apiKey.isEmpty) {
        return const ConnectionTestResult(
          success: false,
          errorMessage: 'API Key未配置',
        );
      }

      // 发送简单请求验证配置
      final response = await _dio.post(
        '$baseUrl/chat/completions',
        options: Options(
          headers: {
            'Authorization': 'Bearer $apiKey',
            'Content-Type': 'application/json',
          },
          sendTimeout: Duration(seconds: config.timeoutSeconds),
          receiveTimeout: Duration(seconds: config.timeoutSeconds),
        ),
        data: {
          'model': config.defaultModel,
          'messages': [
            {'role': 'user', 'content': '你好'}
          ],
          'max_tokens': 10,
        },
      );

      if (response.statusCode == 200) {
        return const ConnectionTestResult(success: true);
      } else {
        return ConnectionTestResult(
          success: false,
          errorMessage: 'HTTP ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      return ConnectionTestResult(
        success: false,
        errorMessage: _getErrorMessage(e),
      );
    } catch (e) {
      return ConnectionTestResult(
        success: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// 图片识别
  Future<AIRecognitionResult> recognizeImage({
    required AIConfig config,
    required String base64Image,
    String? prompt,
  }) async {
    final systemPrompt = prompt ?? _getDefaultImagePrompt();

    try {
      final response = await _callVisionAPI(
        config: config,
        imageBase64: base64Image,
        prompt: systemPrompt,
      );

      return _parseRecognitionResponse(response);
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// 语音解析
  Future<AIRecognitionResult> parseVoice({
    required AIConfig config,
    required String text,
  }) async {
    final systemPrompt = _getDefaultVoicePrompt(text);

    try {
      final response = await _callTextAPI(
        config: config,
        prompt: systemPrompt,
      );

      return _parseRecognitionResponse(response);
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// 调用视觉API（统一使用OpenAI兼容格式）
  Future<Map<String, dynamic>> _callVisionAPI({
    required AIConfig config,
    required String imageBase64,
    required String prompt,
  }) async {
    final baseUrl = _getBaseUrl(config);
    final apiKey = await _getSecureApiKey(config);

    final response = await _dio.post(
      '$baseUrl/chat/completions',
      options: Options(
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        sendTimeout: Duration(seconds: config.timeoutSeconds),
        receiveTimeout: Duration(seconds: config.timeoutSeconds),
      ),
      data: {
        'model': config.defaultModel,
        'messages': [
          {
            'role': 'user',
            'content': [
              {'type': 'text', 'text': prompt},
              {
                'type': 'image_url',
                'image_url': {'url': 'data:image/jpeg;base64,$imageBase64'},
              },
            ],
          },
        ],
        'max_tokens': 1000,
      },
    );

    return response.data;
  }

  /// 调用文本API（统一使用OpenAI兼容格式）
  Future<Map<String, dynamic>> _callTextAPI({
    required AIConfig config,
    required String prompt,
  }) async {
    final baseUrl = _getBaseUrl(config);
    final apiKey = await _getSecureApiKey(config);

    final response = await _dio.post(
      '$baseUrl/chat/completions',
      options: Options(
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        sendTimeout: Duration(seconds: config.timeoutSeconds),
        receiveTimeout: Duration(seconds: config.timeoutSeconds),
      ),
      data: {
        'model': config.defaultModel,
        'messages': [
          {'role': 'user', 'content': prompt},
        ],
        'max_tokens': 1000,
      },
    );

    return response.data;
  }

  /// 解析识别响应
  AIRecognitionResult _parseRecognitionResponse(Map<String, dynamic> response) {
    // 提取响应文本（OpenAI兼容格式）
    String? content;
    if (response['choices'] != null) {
      content = response['choices'][0]['message']['content'] as String?;
    }

    if (content == null) {
      throw Exception('AI响应内容为空');
    }

    // 尝试解析JSON
    try {
      // 查找JSON块
      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(content);
      if (jsonMatch != null) {
        final json = jsonDecode(jsonMatch.group(0)!) as Map<String, dynamic>;
        return _parseResultFromJson(json, content);
      }
    } catch (_) {
      // JSON解析失败，尝试文本解析
    }

    // 文本解析（简单提取）
    return _parseResultFromText(content);
  }

  /// 从JSON解析结果
  AIRecognitionResult _parseResultFromJson(Map<String, dynamic> json, String rawResponse) {
    final name = json['name'] as String? ?? '未知物品';
    final category = json['category'] as String? ?? PresetCategories.food;

    DateTime? purchaseDate;
    if (json['purchase_date'] != null) {
      try {
        purchaseDate = DateTime.parse(json['purchase_date'] as String);
      } catch (_) {}
    }

    DateTime expiryDate;
    if (json['expiry_date'] != null) {
      try {
        expiryDate = DateTime.parse(json['expiry_date'] as String);
      } catch (_) {
        expiryDate = DateTime.now().add(const Duration(days: 7));
      }
    } else {
      expiryDate = DateTime.now().add(const Duration(days: 7));
    }

    return AIRecognitionResult(
      name: name,
      category: category,
      subCategory: json['sub_category'] as String?,
      brand: json['brand'] as String?,
      specification: json['specification'] as String?,
      purchaseDate: purchaseDate,
      expiryDate: expiryDate,
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.8,
      rawResponse: rawResponse,
    );
  }

  /// 从文本解析结果
  AIRecognitionResult _parseResultFromText(String text) {
    // 简单文本解析
    String name = '未知物品';
    String category = PresetCategories.food;
    DateTime expiryDate = DateTime.now().add(const Duration(days: 7));

    // 尝试提取名称
    final nameMatch = RegExp(r'名称[：:]\s*(.+)').firstMatch(text);
    if (nameMatch != null) {
      name = nameMatch.group(1)!.trim();
    }

    // 尝试提取分类
    if (text.contains('药') || text.toLowerCase().contains('drug')) {
      category = PresetCategories.drug;
    }

    // 尝试提取过期日期
    final dateMatch = RegExp(r'过期[日期]*[：:]\s*(\d{4}[-/年]\d{1,2}[-/月]\d{1,2}日?)').firstMatch(text);
    if (dateMatch != null) {
      try {
        final dateStr = dateMatch.group(1)!
            .replaceAll('年', '-')
            .replaceAll('月', '-')
            .replaceAll('日', '');
        expiryDate = DateTime.parse(dateStr);
      } catch (_) {}
    }

    return AIRecognitionResult(
      name: name,
      category: category,
      expiryDate: expiryDate,
      confidence: 0.6,
      rawResponse: text,
    );
  }

  /// 默认图片识别提示词
  String _getDefaultImagePrompt() {
    return '''
请识别图片中的物品信息，并以JSON格式返回以下字段：
{
  "name": "物品名称",
  "category": "分类（如：食品、药品等）",
  "sub_category": "子分类（可选）",
  "brand": "品牌（可选）",
  "specification": "规格（可选）",
  "purchase_date": "购买日期（YYYY-MM-DD格式，可选）",
  "expiry_date": "过期日期（YYYY-MM-DD格式）",
  "confidence": 0.8
}

请只返回JSON，不要包含其他文字。
''';
  }

  /// 默认语音解析提示词
  String _getDefaultVoicePrompt(String text) {
    return '''
请解析以下用户输入，提取物品信息并以JSON格式返回：
"$text"

返回格式：
{
  "name": "物品名称",
  "category": "分类（如：食品、药品等）",
  "sub_category": "子分类（可选）",
  "brand": "品牌（可选）",
  "specification": "规格（可选）",
  "purchase_date": "购买日期（YYYY-MM-DD格式，可选）",
  "expiry_date": "过期日期（YYYY-MM-DD格式）",
  "confidence": 0.8
}

请只返回JSON，不要包含其他文字。
''';
  }

  /// 错误处理
  Exception _handleError(dynamic error) {
    if (error is DioException) {
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.sendTimeout ||
          error.type == DioExceptionType.receiveTimeout) {
        return Exception('请求超时，请检查网络连接');
      }
      if (error.response?.statusCode == 401) {
        return Exception('API Key无效，请检查配置');
      }
      if (error.response?.statusCode == 429) {
        return Exception('请求过于频繁，请稍后再试');
      }
      return Exception('请求失败: ${error.message}');
    }
    return Exception('发生错误: $error');
  }

  /// 获取错误消息字符串
  String _getErrorMessage(dynamic error) {
    if (error is DioException) {
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.sendTimeout ||
          error.type == DioExceptionType.receiveTimeout) {
        return '请求超时，请检查网络连接';
      }
      if (error.response?.statusCode == 401) {
        return 'API Key无效，请检查配置';
      }
      if (error.response?.statusCode == 429) {
        return '请求过于频繁，请稍后再试';
      }
      return '请求失败: ${error.message}';
    }
    return '发生错误: $error';
  }
}
