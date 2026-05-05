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

  /// 日期是否在图片中可见
  final bool dateVisible;
  /// 日期位置的提示（如：日期可能在封口处，建议补拍）
  final String? dateLocationHint;
  /// 过期日期来源：标签显示/推算/默认估算
  final String expiryInfoSource;
  /// 生产日期（如果有）
  final DateTime? productionDate;
  /// 保质期（原始文本，如"12个月"、"180天"）
  final String? shelfLife;

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
    this.dateVisible = true,
    this.dateLocationHint,
    this.expiryInfoSource = '标签显示',
    this.productionDate,
    this.shelfLife,
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

    DateTime? productionDate;
    if (json['production_date'] != null) {
      try {
        productionDate = DateTime.parse(json['production_date'] as String);
      } catch (_) {}
    }

    DateTime expiryDate;
    if (json['expiry_date'] != null) {
      try {
        expiryDate = DateTime.parse(json['expiry_date'] as String);
      } catch (_) {
        // 尝试根据生产日期+保质期推算
        expiryDate = _calculateExpiryDate(
          productionDate: productionDate,
          shelfLife: json['shelf_life'] as String?,
          category: category,
        );
      }
    } else {
      // 没有过期日期，尝试推算
      expiryDate = _calculateExpiryDate(
        productionDate: productionDate,
        shelfLife: json['shelf_life'] as String?,
        category: category,
      );
    }

    final dateVisible = json['date_visible'] as bool? ?? true;
    final expiryInfoSource = json['expiry_info_source'] as String? ?? '默认估算';

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
      dateVisible: dateVisible,
      dateLocationHint: json['date_location_hint'] as String?,
      expiryInfoSource: expiryInfoSource,
      productionDate: productionDate,
      shelfLife: json['shelf_life'] as String?,
    );
  }

  /// 根据生产日期和保质期推算过期日期
  DateTime _calculateExpiryDate({
    DateTime? productionDate,
    String? shelfLife,
    required String category,
  }) {
    final now = DateTime.now();

    // 如果有生产日期和保质期，推算过期日期
    if (productionDate != null && shelfLife != null) {
      final days = _parseShelfLifeToDays(shelfLife);
      if (days > 0) {
        return productionDate.add(Duration(days: days));
      }
    }

    // 根据分类返回默认保质期
    final defaultDays = _getDefaultShelfLifeDays(category);
    return now.add(Duration(days: defaultDays));
  }

  /// 解析保质期文本为天数
  int _parseShelfLifeToDays(String shelfLife) {
    final text = shelfLife.trim();

    // 匹配 "X天"
    var match = RegExp(r'(\d+)\s*天').firstMatch(text);
    if (match != null) {
      return int.parse(match.group(1)!);
    }

    // 匹配 "X个月" 或 "X月"
    match = RegExp(r'(\d+)\s*个?月').firstMatch(text);
    if (match != null) {
      return int.parse(match.group(1)!) * 30;
    }

    // 匹配 "X年"
    match = RegExp(r'(\d+)\s*年').firstMatch(text);
    if (match != null) {
      return int.parse(match.group(1)!) * 365;
    }

    return 0;
  }

  /// 根据分类获取默认保质期天数
  int _getDefaultShelfLifeDays(String category) {
    switch (category) {
      case '食品':
        return 30; // 食品默认30天
      case '药品':
        return 365; // 药品默认1年
      case '化妆品':
        return 365; // 化妆品默认1年（未开封）
      case '日用品':
        return 730; // 日用品默认2年
      default:
        return 90; // 其他默认90天
    }
  }

  /// 从文本解析结果
  AIRecognitionResult _parseResultFromText(String text) {
    // 简单文本解析
    String name = '未知物品';
    String category = PresetCategories.food;
    DateTime expiryDate = _calculateExpiryDate(category: category);

    // 尝试提取名称
    final nameMatch = RegExp(r'名称[：:]\s*(.+)').firstMatch(text);
    if (nameMatch != null) {
      name = nameMatch.group(1)!.trim();
    }

    // 尝试提取分类
    if (text.contains('药') || text.toLowerCase().contains('drug')) {
      category = PresetCategories.drug;
    } else if (text.contains('化妆') || text.contains('护肤')) {
      category = '化妆品';
    } else if (text.contains('日用')) {
      category = '日用品';
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
      dateVisible: false,
      expiryInfoSource: '默认估算',
    );
  }

  /// 默认图片识别提示词
  String _getDefaultImagePrompt() {
    final today = DateTime.now().toString().split(' ')[0];
    return '''
你是一个物品信息识别助手。请仔细分析图片中的物品包装。

【重要规则】
1. 如果图片模糊或无法识别，confidence < 0.3，name 说明原因
2. 部分识别 confidence 0.5-0.7
3. 清晰识别 confidence 0.8-1.0

【日期识别说明 - 特别注意】
生产日期/过期日期通常不在主标签区域，常见位置：
- 封口处、瓶盖、拉环附近（最常见）
- 包装侧面或底部
- 单独的喷码/压印
- 贴纸标签

请仔细检查图片中所有可见区域。如果：
- 没有看到明确的日期 → date_visible 设为 false
- 只看到生产日期+保质期 → 需推算过期日期
- 明确看到过期日期 → 直接使用

【分类选项】
"食品"、"药品"、"化妆品"、"日用品"、"其他"

【返回格式】严格返回JSON，不要添加其他文字：
{
  "name": "物品名称（必填）",
  "category": "分类（必填，必须是上述分类选项之一）",
  "sub_category": "子分类（可选）",
  "brand": "品牌（可选）",
  "specification": "规格（可选）",
  "date_visible": false,
  "date_location_hint": "日期可能在封口处或瓶盖，建议补拍",
  "production_date": "生产日期（YYYY-MM-DD，可见则填）",
  "shelf_life": "保质期（如：12个月、180天，可见则填）",
  "expiry_date": "过期日期（YYYY-MM-DD，尽量推算）",
  "expiry_info_source": "标签显示/推算/默认估算",
  "confidence": 0.85
}

今天日期：$today
''';
  }

  /// 默认语音解析提示词
  String _getDefaultVoicePrompt(String text) {
    final today = DateTime.now().toString().split(' ')[0];
    return '''
你是一个语音输入解析助手。请解析用户的语音输入，提取物品信息。

【用户输入】
"$text"

【重要规则】
1. 如果用户输入模糊或无法解析，confidence < 0.3
2. 部分可解析 confidence 0.5-0.7
3. 清晰完整 confidence 0.8-1.0

【分类选项】
"食品"、"药品"、"化妆品"、"日用品"、"其他"

【日期处理规则】
- "明天过期" → 过期日期为今天+1天
- "下周过期" → 过期日期为今天+7天
- "保质期3个月" → 根据购买日期推算
- 如果用户没提日期 → expiry_info_source 设为"默认估算"，根据物品类型给合理默认值

【返回格式】严格返回JSON，不要添加其他文字：
{
  "name": "物品名称（必填）",
  "category": "分类（必填，必须是上述分类选项之一）",
  "sub_category": "子分类（可选）",
  "brand": "品牌（可选）",
  "specification": "规格（可选）",
  "date_visible": true,
  "date_location_hint": "",
  "production_date": "生产日期（YYYY-MM-DD，用户提及则填）",
  "shelf_life": "保质期（用户提及则填）",
  "expiry_date": "过期日期（YYYY-MM-DD，必填）",
  "expiry_info_source": "用户指定/推算/默认估算",
  "confidence": 0.85
}

今天日期：$today
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
