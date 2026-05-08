import 'dart:convert';
import 'package:dio/dio.dart';
import '../models/ai_config.dart';
import '../utils/constants.dart';
import 'secure_storage_service.dart';
import 'image_preprocessing_service.dart';

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

/// 物品识别结果（Step 1）
class ItemIdentification {
  final String name;
  final String category;
  final String? brand;
  final String? specification;

  const ItemIdentification({
    required this.name,
    required this.category,
    this.brand,
    this.specification,
  });
}

/// 日期解析结果（Step 2）
class DateParsingResult {
  final List<RecognizedDate> datesFound;
  final String? shelfLifeText;
  final int? shelfLifeMonths;

  const DateParsingResult({
    required this.datesFound,
    this.shelfLifeText,
    this.shelfLifeMonths,
  });
}

/// 识别到的日期
class RecognizedDate {
  final String rawText;
  final DateTime? parsedDate;
  final String formatType;
  final String likelyType;
  final String? location;

  const RecognizedDate({
    required this.rawText,
    this.parsedDate,
    required this.formatType,
    required this.likelyType,
    this.location,
  });
}

/// 日期验证结果（Step 3）
class DateValidationResult {
  final DateTime? productionDate;
  final DateTime? expiryDate;
  final bool validationPassed;
  final double confidence;
  final String? notes;

  const DateValidationResult({
    this.productionDate,
    this.expiryDate,
    required this.validationPassed,
    required this.confidence,
    this.notes,
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

/// 保质期分析结果
class ShelfLifeAnalysis {
  final String analysis;
  final double confidence;

  const ShelfLifeAnalysis({
    required this.analysis,
    required this.confidence,
  });
}

/// 开封保质期分析结果
class OpenedExpiryAnalysis {
  final int suggestedDays;
  final String? reasoning;
  final String? storageTip;

  const OpenedExpiryAnalysis({
    required this.suggestedDays,
    this.reasoning,
    this.storageTip,
  });
}

/// AI服务
class AIService {
  static final AIService _instance = AIService._internal();
  factory AIService() => _instance;
  AIService._internal();

  final Dio _dio = Dio();
  final SecureStorageService _secureStorage = SecureStorageService();
  final ImagePreprocessingService _preprocessingService = ImagePreprocessingService();

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

  /// 分析物品保质期
  Future<ShelfLifeAnalysis> analyzeShelfLife({
    required AIConfig config,
    required String name,
    required String category,
    String? subCategory,
    required bool isOpened,
    required int daysRemaining,
  }) async {
    final prompt = _getShelfLifePrompt(
      name: name,
      category: category,
      subCategory: subCategory,
      isOpened: isOpened,
      daysRemaining: daysRemaining,
    );

    try {
      final response = await _callTextAPI(
        config: config,
        prompt: prompt,
      );

      String? content;
      if (response['choices'] != null) {
        content = response['choices'][0]['message']['content'] as String?;
      }

      if (content == null) {
        throw Exception('AI响应内容为空');
      }

      // 清理markdown代码块标记
      String cleanContent = content.trim();
      // 移除首尾的 ```xxx 和 ```
      final codeBlockRegex = RegExp(r'^```[\w]*\n?([\s\S]*?)\n?```$');
      final match = codeBlockRegex.firstMatch(cleanContent);
      if (match != null) {
        cleanContent = match.group(1)!.trim();
      }

      return ShelfLifeAnalysis(
        analysis: cleanContent,
        confidence: 0.85,
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// 分析物品开封后的保质期
  Future<OpenedExpiryAnalysis> analyzeOpenedExpiry({
    required AIConfig config,
    required String name,
    required String category,
    String? subCategory,
    String? brand,
    String? specification,
    String? location,
  }) async {
    final prompt = _getOpenedExpiryPrompt(
      name: name,
      category: category,
      subCategory: subCategory,
      brand: brand,
      specification: specification,
      location: location,
    );

    try {
      final response = await _callTextAPI(
        config: config,
        prompt: prompt,
      );

      final content = _extractContent(response);
      if (content == null) {
        throw Exception('AI响应内容为空');
      }

      final json = _parseJsonFromContent(content);
      return OpenedExpiryAnalysis(
        suggestedDays: json['suggested_days'] as int? ?? 7,
        reasoning: json['reasoning'] as String?,
        storageTip: json['storage_tip'] as String?,
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// 保质期分析提示词
  String _getShelfLifePrompt({
    required String name,
    required String category,
    String? subCategory,
    required bool isOpened,
    required int daysRemaining,
  }) {
    final today = DateTime.now().toString().split(' ')[0];
    final openStatus = isOpened ? '已开封' : '未开封';

    return '''
你是一个物品保质期分析专家。请根据以下信息，给出简短的保质期建议。

【物品信息】
- 名称：$name
- 分类：$category${subCategory != null ? ' ($subCategory)' : ''}
- 状态：$openStatus
- 剩余天数：$daysRemaining 天

【分析要求】
1. 如果已开封，说明开封后的保质期变化
2. 给出存储建议（温度、位置等）
3. 提醒食用/使用优先级
4. 字数控制在100字以内

【返回格式】
直接返回分析文本，不要添加标题、代码块、markdown格式。

今天日期：$today
''';
  }

  /// 开封保质期分析提示词
  String _getOpenedExpiryPrompt({
    required String name,
    required String category,
    String? subCategory,
    String? brand,
    String? specification,
    String? location,
  }) {
    final today = DateTime.now().toString().split(' ')[0];

    return '''
你是物品保质期分析专家。请根据以下物品信息，给出开封后的建议使用天数。

【物品信息】
- 名称：$name
- 分类：$category${subCategory != null ? ' ($subCategory)' : ''}
- 品牌：${brand ?? '未知'}
- 规格：${specification ?? '未知'}
- 存放位置：${location ?? '未知'}

【分析要求】
1. 根据物品类型评估开封后的保质期
2. 考虑存放位置对保质期的影响（如冰箱 vs 常温）
3. 给出简短的原因说明（20字以内）
4. 给出存储建议（15字以内）

【返回格式】严格返回JSON，不要添加其他文字：
{
  "suggested_days": 7,
  "reasoning": "简短说明原因",
  "storage_tip": "存储建议"
}

今天日期：$today
''';
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

【语音纠错规则】
由于语音识别可能存在同音字错误，请根据上下文智能纠错：

1. 常见品牌名纠错：
   - "乐世/乐事/勒是/乐师" → 乐事（薯片品牌）
   - "康帅傅/康师傅/康世富" → 康师傅
   - "奥利奥/奥利澳/澳利奥" → 奥利奥
   - "特浓苏/特仑苏/特伦苏" → 特仑苏（牛奶品牌）
   - "养乐多/养乐朵/洋乐多" → 养乐多
   - "伊利/一利/亿利" → 伊利
   - "蒙牛/猛牛/梦牛" → 蒙牛
   - "旺旺/王王/望旺" → 旺旺
   - "三全/三泉" → 三全
   - "思念/思恋/私念" → 思念

2. 商品类别推断：
   - 听到"薯片/薯条/脆片" → category为"食品"，sub_category为"零食"
   - 听到"牛奶/纯牛奶/鲜奶" → category为"食品"，sub_category为"乳制品"
   - 听到"酸奶/优酸乳" → category为"食品"，sub_category为"酸奶"
   - 听到"酱油/蚝油/醋" → category为"食品"，sub_category为"调味品"

3. 同音字处理：
   - 结合商品类别判断最可能的汉字组合
   - 如果用户提到品牌特征词（如"薯片"），优先匹配相关品牌

【分类选项】
"食品"、"药品"、"化妆品"、"日用品"、"其他"

【日期处理规则】
- "明天过期" → 过期日期为今天+1天
- "下周过期" → 过期日期为今天+7天
- "保质期3个月" → 根据购买日期推算
- "刚买的"/"新买的" → 购买日期为今天
- 如果用户没提日期 → expiry_info_source 设为"默认估算"，根据物品类型给合理默认值

【返回格式】严格返回JSON，不要添加其他文字：
{
  "name": "物品名称（必填，已纠错）",
  "category": "分类（必填，必须是上述分类选项之一）",
  "sub_category": "子分类（可选）",
  "brand": "品牌（可选，已纠错）",
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

  // ============================================================
  // Agent 工作流方法
  // ============================================================

  /// 使用 Agent 工作流识别图片（增强版）
  Future<AIRecognitionResult> recognizeImageWithAgent({
    required AIConfig config,
    required String originalImageBase64,
    String? enhancedImageBase64,
  }) async {
    final today = DateTime.now().toString().split(' ')[0];

    // Step 1 和 Step 2 并行执行（互不依赖）
    final results = await Future.wait([
      _step1_IdentifyItem(config, originalImageBase64, enhancedImageBase64),
      _step2_ParseDates(config, originalImageBase64, enhancedImageBase64, today),
    ]);

    final itemInfo = results[0] as ItemIdentification;
    final dateInfo = results[1] as DateParsingResult;

    // Step 3: 逻辑验证（依赖 Step 2 结果）
    final validatedInfo = await _step3_ValidateDates(config, dateInfo, today);

    // Step 4: 智能推算（本地计算）
    final finalResult = _step4_CalculateExpiry(validatedInfo, itemInfo, today);

    return finalResult;
  }

  /// Step 1: 物品识别
  Future<ItemIdentification> _step1_IdentifyItem(
    AIConfig config,
    String originalImageBase64,
    String? enhancedImageBase64,
  ) async {
    final prompt = '''
你是物品识别助手。请识别图片中的物品基本信息。

【识别目标】
- 名称（必填）
- 分类：食品/药品/化妆品/日用品/其他
- 品牌（如有）
- 规格（如有）

【返回格式】严格返回JSON，不要添加其他文字：
{
  "name": "物品名称",
  "category": "分类",
  "brand": "品牌",
  "specification": "规格"
}
''';

    final response = await _callVisionAPIWithDualImages(
      config: config,
      originalImageBase64: originalImageBase64,
      enhancedImageBase64: enhancedImageBase64,
      prompt: prompt,
    );

    final content = _extractContent(response);
    final json = _parseJsonFromContent(content);

    return ItemIdentification(
      name: json['name'] as String? ?? '未知物品',
      category: json['category'] as String? ?? PresetCategories.food,
      brand: json['brand'] as String?,
      specification: json['specification'] as String?,
    );
  }

  /// Step 2: 日期解析
  Future<DateParsingResult> _step2_ParseDates(
    AIConfig config,
    String originalImageBase64,
    String? enhancedImageBase64,
    String today,
  ) async {
    final prompt = '''
你是日期解析专家。请仔细扫描图片中的所有日期相关信息。

【当前日期】$today

【日期格式说明】
1. 标准格式：2024-01-01、2024/01/01
2. 中文格式：2024年1月1日
3. 纯数字格式：20260325（YYYYMMDD，常见于喷码）
4. 其他格式：20240101、2024.01.01

【特别注意】
- 喷码通常在包装底部、封口处、瓶盖边缘
- 喷码颜色可能较淡，请仔细查看
- 单独的数字通常是生产日期
- 如果有两个日期，较早的是生产日期，较晚的是过期日期

【保质期文字】
常见的保质期表述：保质期9个月、保质期12个月、保质期180天等

【返回格式】严格返回JSON，不要添加其他文字：
{
  "dates_found": [
    {
      "raw_text": "20260325",
      "parsed_date": "2026-03-25",
      "format_type": "纯数字喷码",
      "likely_type": "生产日期",
      "location": "包装底部"
    }
  ],
  "shelf_life_text": "保质期9个月",
  "shelf_life_months": 9
}

如果找不到日期，返回空数组：
{
  "dates_found": [],
  "shelf_life_text": null,
  "shelf_life_months": null
}
''';

    final response = await _callVisionAPIWithDualImages(
      config: config,
      originalImageBase64: originalImageBase64,
      enhancedImageBase64: enhancedImageBase64,
      prompt: prompt,
    );

    final content = _extractContent(response);
    final json = _parseJsonFromContent(content);

    final datesFound = (json['dates_found'] as List<dynamic>?)
        ?.map((d) => RecognizedDate(
              rawText: d['raw_text'] as String? ?? '',
              parsedDate: d['parsed_date'] != null
                  ? DateTime.tryParse(d['parsed_date'] as String)
                  : null,
              formatType: d['format_type'] as String? ?? '未知格式',
              likelyType: d['likely_type'] as String? ?? '未知',
              location: d['location'] as String?,
            ))
        .toList() ?? [];

    return DateParsingResult(
      datesFound: datesFound,
      shelfLifeText: json['shelf_life_text'] as String?,
      shelfLifeMonths: json['shelf_life_months'] as int?,
    );
  }

  /// Step 3: 逻辑验证
  Future<DateValidationResult> _step3_ValidateDates(
    AIConfig config,
    DateParsingResult dateInfo,
    String today,
  ) async {
    final datesJson = dateInfo.datesFound
        .map((d) => {
              'raw': d.rawText,
              'parsed': d.parsedDate?.toString().split(' ')[0],
              'type': d.likelyType,
            })
        .toList();

    final prompt = '''
你是日期逻辑验证专家。请验证以下日期信息的合理性。

【当前日期】$today

【识别到的日期】
${jsonEncode(datesJson)}

【保质期信息】
文本: ${dateInfo.shelfLifeText ?? '未识别'}
月数: ${dateInfo.shelfLifeMonths ?? '未识别'}

【验证规则】
1. 生产日期应早于当前日期（除非是未来生产的商品）
2. 过期日期应晚于当前日期（除非已经过期）
3. 如有"保质期X个月"文字，结合生产日期推算过期日期
4. 纯数字喷码通常是生产日期，需要结合保质期推算过期日期

【推算示例】
生产日期: 2026-03-25，保质期: 9个月
→ 过期日期: 2026-12-25

【返回格式】严格返回JSON：
{
  "production_date": "YYYY-MM-DD 或 null",
  "expiry_date": "YYYY-MM-DD",
  "validation_passed": true,
  "confidence": 0.95,
  "notes": "验证说明"
}
''';

    final response = await _callTextAPI(config: config, prompt: prompt);
    final content = _extractContent(response);
    final json = _parseJsonFromContent(content);

    return DateValidationResult(
      productionDate: json['production_date'] != null
          ? DateTime.tryParse(json['production_date'] as String)
          : null,
      expiryDate: json['expiry_date'] != null
          ? DateTime.tryParse(json['expiry_date'] as String)
          : null,
      validationPassed: json['validation_passed'] as bool? ?? false,
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.5,
      notes: json['notes'] as String?,
    );
  }

  /// Step 4: 智能推算并生成最终结果
  AIRecognitionResult _step4_CalculateExpiry(
    DateValidationResult validatedInfo,
    ItemIdentification itemInfo,
    String today,
  ) {
    DateTime expiryDate;
    String expiryInfoSource;
    bool dateVisible = true;
    String? dateLocationHint;

    if (validatedInfo.expiryDate != null) {
      // 有明确的过期日期
      expiryDate = validatedInfo.expiryDate!;
      expiryInfoSource = '标签显示';
    } else if (validatedInfo.productionDate != null) {
      // 只有生产日期，使用默认保质期
      final defaultDays = _getDefaultShelfLifeDays(itemInfo.category);
      expiryDate = validatedInfo.productionDate!.add(Duration(days: defaultDays));
      expiryInfoSource = '推算';
    } else {
      // 没有任何日期，使用默认值
      final defaultDays = _getDefaultShelfLifeDays(itemInfo.category);
      expiryDate = DateTime.parse(today).add(Duration(days: defaultDays));
      expiryInfoSource = '默认估算';
      dateVisible = false;
      dateLocationHint = '未识别到日期，请手动确认';
    }

    return AIRecognitionResult(
      name: itemInfo.name,
      category: itemInfo.category,
      brand: itemInfo.brand,
      specification: itemInfo.specification,
      expiryDate: expiryDate,
      confidence: validatedInfo.confidence,
      dateVisible: dateVisible,
      dateLocationHint: dateLocationHint,
      expiryInfoSource: expiryInfoSource,
      productionDate: validatedInfo.productionDate,
    );
  }

  /// 调用视觉 API（支持双图片）
  Future<Map<String, dynamic>> _callVisionAPIWithDualImages({
    required AIConfig config,
    required String originalImageBase64,
    String? enhancedImageBase64,
    required String prompt,
  }) async {
    final baseUrl = _getBaseUrl(config);
    final apiKey = await _getSecureApiKey(config);

    // 构建图片内容
    final List<Map<String, dynamic>> imageContents = [
      {
        'type': 'image_url',
        'image_url': {'url': 'data:image/jpeg;base64,$originalImageBase64'},
      },
    ];

    // 如果有增强版本，添加第二个图片
    if (enhancedImageBase64 != null) {
      imageContents.add({
        'type': 'image_url',
        'image_url': {'url': 'data:image/jpeg;base64,$enhancedImageBase64'},
      });
    }

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
              ...imageContents,
            ],
          },
        ],
        'max_tokens': 1500,
      },
    );

    return response.data;
  }

  /// 从响应中提取内容
  String? _extractContent(Map<String, dynamic> response) {
    if (response['choices'] != null) {
      return response['choices'][0]['message']['content'] as String?;
    }
    return null;
  }

  /// 从内容中解析 JSON
  Map<String, dynamic> _parseJsonFromContent(String? content) {
    if (content == null) return {};

    try {
      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(content);
      if (jsonMatch != null) {
        return jsonDecode(jsonMatch.group(0)!) as Map<String, dynamic>;
      }
    } catch (_) {}

    return {};
  }
}
