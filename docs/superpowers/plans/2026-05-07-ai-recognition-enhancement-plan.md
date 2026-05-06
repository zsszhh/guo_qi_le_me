# AI识别增强与体验优化实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 修复深色模式显示异常、日期选择器中文化、AI识别增强（结构化Agent工作流+图片预处理）、AI识别图片自动加载

**Architecture:** 分三阶段实施：Phase 1 基础修复（禁用深色模式+添加依赖），Phase 2 体验优化（日期选择器+图片自动加载），Phase 3 AI增强（预处理+Agent工作流）

**Tech Stack:** Flutter、flutter_datetime_picker_plus、image库、Dio

---

## 文件结构

| 文件 | 职责 | 改动类型 |
|------|------|----------|
| `pubspec.yaml` | 依赖管理 | 修改 |
| `lib/app.dart` | 应用主题配置 | 修改 |
| `lib/pages/item_edit_page.dart` | 物品编辑页（日期选择器+图片加载） | 修改 |
| `lib/pages/ai_input_page.dart` | AI录入页（集成预处理+Agent） | 修改 |
| `lib/services/ai_service.dart` | AI服务（Agent工作流） | 重构 |
| `lib/services/image_preprocessing_service.dart` | 图片预处理服务 | 新增 |
| `lib/models/prefilled_data.dart` | 预填充数据模型 | 新增 |

---

## Phase 1: 基础修复

### Task 1: 禁用深色模式

**Files:**
- Modify: `lib/app.dart:28`

- [ ] **Step 1: 修改 themeMode 为 light**

```dart
// lib/app.dart 第 28 行
// 修改前:
themeMode: ThemeMode.system,

// 修改后:
themeMode: ThemeMode.light,
```

- [ ] **Step 2: 验证修改**

运行应用，在系统深色模式下打开应用，确认界面显示正常（浅色背景+深色文字）。

- [ ] **Step 3: 提交**

```bash
git add lib/app.dart
git commit -m "fix: 暂时禁用深色模式修复显示异常

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>"
```

---

### Task 2: 添加依赖

**Files:**
- Modify: `pubspec.yaml`

- [ ] **Step 1: 添加 flutter_datetime_picker_plus 和 image 依赖**

```yaml
# pubspec.yaml 在 dependencies 部分添加

  # 日期选择器（中文支持）
  flutter_datetime_picker_plus: ^3.0.0

  # 图片处理
  image: ^4.0.0
```

- [ ] **Step 2: 安装依赖**

```bash
cd H:/code/food_app
flutter pub get
```

预期输出：依赖安装成功，无冲突

- [ ] **Step 3: 提交**

```bash
git add pubspec.yaml pubspec.lock
git commit -m "chore: 添加 flutter_datetime_picker_plus 和 image 依赖

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>"
```

---

## Phase 2: 体验优化

### Task 3: 创建 PrefilledData 模型文件

**Files:**
- Create: `lib/models/prefilled_data.dart`

- [ ] **Step 1: 创建 PrefilledData 数据类**

```dart
// lib/models/prefilled_data.dart

/// 预填充数据（用于 AI 识别结果）
class PrefilledData {
  final String? name;
  final String? category;
  final String? brand;
  final String? specification;
  final DateTime? purchaseDate;
  final DateTime? expiryDate;
  final double? aiConfidence;
  final bool dateVisible;
  final String? dateLocationHint;
  final String expiryInfoSource;
  final String? imageUrl;

  const PrefilledData({
    this.name,
    this.category,
    this.brand,
    this.specification,
    this.purchaseDate,
    this.expiryDate,
    this.aiConfidence,
    this.dateVisible = true,
    this.dateLocationHint,
    this.expiryInfoSource = '标签显示',
    this.imageUrl,
  });
}
```

- [ ] **Step 2: 提交**

```bash
git add lib/models/prefilled_data.dart
git commit -m "feat: 创建 PrefilledData 数据模型，新增 imageUrl 字段

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>"
```

---

### Task 4: 修改 ItemEditPage 导入和 PrefilledData 引用

**Files:**
- Modify: `lib/pages/item_edit_page.dart`

- [ ] **Step 1: 修改导入，使用独立的 PrefilledData 模型**

```dart
// lib/pages/item_edit_page.dart 第 1-17 行
// 修改导入部分

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../theme/colors.dart';
import '../theme/typography.dart';
import '../theme/spacing.dart';
import '../utils/constants.dart';
import '../providers/item_provider.dart';
import '../models/item.dart';
import '../models/custom_option.dart';
import '../models/prefilled_data.dart';  // 新增：导入独立模型
import '../widgets/editable_dropdown.dart';
import '../services/product_image_service.dart';

// 删除原来的 PrefilledData 类定义（第 19-43 行）
```

- [ ] **Step 2: 修改 _applyPrefilledData 方法，添加图片加载逻辑**

```dart
// lib/pages/item_edit_page.dart
// 在 _applyPrefilledData() 方法中添加图片加载

void _applyPrefilledData() {
  final data = widget.prefilledData!;
  _nameController.text = data.name ?? '';
  _brandController.text = data.brand ?? '';
  _specificationController.text = data.specification ?? '';
  if (data.category != null) {
    _category = data.category!;
  }
  if (data.purchaseDate != null) {
    _purchaseDate = data.purchaseDate!;
  }
  if (data.expiryDate != null) {
    _expiryDate = data.expiryDate!;
  }
  // 新增：加载 AI 识别的图片
  if (data.imageUrl != null && data.imageUrl!.isNotEmpty) {
    _imageUrl = data.imageUrl;
    _selectedImage = File(data.imageUrl!);
  }
}
```

- [ ] **Step 3: 提交**

```bash
git add lib/pages/item_edit_page.dart
git commit -m "refactor: 使用独立 PrefilledData 模型，支持自动加载 AI 识别图片

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>"
```

---

### Task 5: 替换日期选择器为中文版本

**Files:**
- Modify: `lib/pages/item_edit_page.dart`

- [ ] **Step 1: 添加 flutter_datetime_picker_plus 导入**

```dart
// lib/pages/item_edit_page.dart 导入部分添加
import 'package:flutter_datetime_picker_plus/flutter_datetime_picker_plus.dart';
```

- [ ] **Step 2: 重写 _selectDate 方法，使用中文日期选择器**

```dart
// lib/pages/item_edit_page.dart
// 替换 _selectDate 方法（约第 604-638 行）

Future<void> _selectDate({
  bool isPurchaseDate = false,
  bool isExpiryDate = false,
  bool isOpenedDate = false,
}) async {
  DateTime initialDate;
  String title;
  DateTime minDate;
  DateTime maxDate;

  if (isPurchaseDate) {
    initialDate = _purchaseDate;
    title = '选择购买日期';
    minDate = DateTime(2020);
    maxDate = DateTime.now().add(const Duration(days: 365));
  } else if (isExpiryDate) {
    initialDate = _expiryDate;
    title = '选择过期日期';
    minDate = DateTime.now().subtract(const Duration(days: 365));
    maxDate = DateTime(2030);
  } else if (isOpenedDate) {
    initialDate = _openedDate ?? DateTime.now();
    title = '选择开封日期';
    minDate = DateTime(2020);
    maxDate = DateTime.now().add(const Duration(days: 365));
  } else {
    return;
  }

  await DatePicker.showDatePicker(
    context,
    showTitleActions: true,
    minTime: minDate,
    maxTime: maxDate,
    initialDate: initialDate,
    locale: LocaleType.zh,
    onConfirm: (date) {
      setState(() {
        if (isPurchaseDate) {
          _purchaseDate = date;
        } else if (isExpiryDate) {
          _expiryDate = date;
        } else if (isOpenedDate) {
          _openedDate = date;
        }
      });
    },
    currentTime: initialDate,
  );
}
```

- [ ] **Step 3: 验证日期选择器**

运行应用，进入添加物品页面，点击日期选择，确认显示中文界面。

- [ ] **Step 4: 提交**

```bash
git add lib/pages/item_edit_page.dart
git commit -m "feat: 使用 flutter_datetime_picker_plus 替换日期选择器，支持中文显示

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>"
```

---

### Task 6: 修改 AIInputPage 传递图片路径

**Files:**
- Modify: `lib/pages/ai_input_page.dart`

- [ ] **Step 1: 导入 PrefilledData 模型**

```dart
// lib/pages/ai_input_page.dart 第 17 行后添加
import '../models/prefilled_data.dart';
```

- [ ] **Step 2: 删除原来的 item_edit_page.dart 中 PrefilledData 的引用**

确保不再从 item_edit_page.dart 导入 PrefilledData（因为现在有独立模型文件）

- [ ] **Step 3: 修改 _handlePhotoRecognition 方法，保存图片路径并传递**

```dart
// lib/pages/ai_input_page.dart
// 在 _handlePhotoRecognition 方法中，修改图片选择后的逻辑
// 约第 273-364 行

/// 拍照识别
void _handlePhotoRecognition() async {
  final config = await _checkAIConfig();
  if (config == null) return;

  // 选择图片来源
  final source = await showModalBottomSheet<ImageSource>(
    context: context,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.camera_alt),
            title: const Text('拍照'),
            onTap: () => Navigator.pop(context, ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library),
            title: const Text('从相册选择'),
            onTap: () => Navigator.pop(context, ImageSource.gallery),
          ),
        ],
      ),
    ),
  );

  if (source == null) return;

  setState(() {
    _isLoading = true;
    _loadingText = '正在获取图片...';
  });

  // 保存图片路径变量
  String? selectedImagePath;

  try {
    // 获取图片
    final XFile? image = await _imagePicker.pickImage(
      source: source,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );

    if (image == null) {
      setState(() => _isLoading = false);
      return;
    }

    // 保存图片路径
    selectedImagePath = image.path;

    setState(() => _loadingText = 'AI 正在识别...');

    // 读取图片并转Base64
    final bytes = await File(image.path).readAsBytes();
    final base64Image = base64Encode(bytes);

    // 调用AI识别
    final result = await _aiService.recognizeImage(
      config: config,
      base64Image: base64Image,
    );

    setState(() => _isLoading = false);

    // 跳转到预填充表单页面
    if (mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => ItemEditPage(
            prefilledData: PrefilledData(
              name: result.name,
              category: result.category,
              brand: result.brand,
              specification: result.specification,
              expiryDate: result.expiryDate,
              purchaseDate: result.purchaseDate,
              aiConfidence: result.confidence,
              dateVisible: result.dateVisible,
              dateLocationHint: result.dateLocationHint,
              expiryInfoSource: result.expiryInfoSource,
              imageUrl: selectedImagePath,  // 新增：传递图片路径
            ),
          ),
        ),
      );
    }
  } catch (e) {
    setState(() => _isLoading = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('识别失败: $e')),
      );
    }
  }
}
```

- [ ] **Step 4: 验证图片自动加载**

运行应用，拍照识别后进入编辑页，确认图片自动显示。

- [ ] **Step 5: 提交**

```bash
git add lib/pages/ai_input_page.dart
git commit -m "feat: AI识别后自动传递图片路径到编辑页

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>"
```

---

## Phase 3: AI 增强

### Task 7: 创建图片预处理服务

**Files:**
- Create: `lib/services/image_preprocessing_service.dart`

- [ ] **Step 1: 创建图片预处理服务**

```dart
// lib/services/image_preprocessing_service.dart

import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;

/// 预处理后的图片结果
class PreprocessedImages {
  /// 原始图片字节
  final Uint8List original;

  /// 增强后的图片字节
  final Uint8List enhanced;

  const PreprocessedImages({
    required this.original,
    required this.enhanced,
  });
}

/// 图片预处理服务
/// 用于增强图片质量，提高 AI 识别准确率
class ImagePreprocessingService {
  static final ImagePreprocessingService _instance = ImagePreprocessingService._internal();
  factory ImagePreprocessingService() => _instance;
  ImagePreprocessingService._internal();

  /// 预处理图片，生成增强版本
  /// 
  /// 处理步骤：
  /// 1. 对比度增强 (+30%)
  /// 2. 锐化处理
  /// 3. 自适应亮度调整
  Future<Uint8List> enhanceImage(Uint8List originalBytes) async {
    final image = img.decodeImage(originalBytes);
    if (image == null) {
      throw Exception('无法解码图片');
    }

    // 1. 对比度增强 (+30%)
    var enhanced = img.adjustColor(image, contrast: 1.3);

    // 2. 锐化处理（使用卷积核）
    enhanced = img.convolution(
      enhanced,
      filter: [
        [0, -1, 0],
        [-1, 5, -1],
        [0, -1, 0]
      ],
    );

    // 3. 自适应亮度调整
    enhanced = img.adjustColor(enhanced, brightness: 0.1);

    // 编码为 JPEG
    return Uint8List.fromList(img.encodeJpg(enhanced, quality: 90));
  }

  /// 生成双版本图片（原图 + 增强版）
  /// 
  /// 用于发送给 AI 进行对比识别
  Future<PreprocessedImages> preprocess(File imageFile) async {
    final originalBytes = await imageFile.readAsBytes();
    final enhancedBytes = await enhanceImage(originalBytes);

    return PreprocessedImages(
      original: originalBytes,
      enhanced: enhancedBytes,
    );
  }

  /// 将图片转换为 Base64
  String toBase64(Uint8List bytes) {
    return base64Encode(bytes);
  }
}

// 需要添加 dart:convert 导入
import 'dart:convert';
```

- [ ] **Step 2: 修正导入顺序**

```dart
// lib/services/image_preprocessing_service.dart
// 正确的导入顺序

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
```

- [ ] **Step 3: 提交**

```bash
git add lib/services/image_preprocessing_service.dart
git commit -m "feat: 创建图片预处理服务，支持对比度增强和锐化

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>"
```

---

### Task 8: 重构 AI 服务 - 添加 Agent 工作流

**Files:**
- Modify: `lib/services/ai_service.dart`

- [ ] **Step 1: 添加 Agent 工作流相关导入和常量**

```dart
// lib/services/ai_service.dart
// 在文件开头添加

import 'dart:convert';
import 'package:dio/dio.dart';
import '../models/ai_config.dart';
import '../utils/constants.dart';
import 'secure_storage_service.dart';
import 'image_preprocessing_service.dart';
```

- [ ] **Step 2: 添加 Agent 工作流的中间数据模型**

```dart
// lib/services/ai_service.dart
// 在 AIRecognitionResult 类之后添加

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
```

- [ ] **Step 3: 添加 Agent 工作流主方法**

```dart
// lib/services/ai_service.dart
// 在 AIService 类中添加

final ImagePreprocessingService _preprocessingService = ImagePreprocessingService();

/// 使用 Agent 工作流识别图片（增强版）
Future<AIRecognitionResult> recognizeImageWithAgent({
  required AIConfig config,
  required String originalImageBase64,
  String? enhancedImageBase64,
}) async {
  final today = DateTime.now().toString().split(' ')[0];

  // Step 1: 物品识别
  final itemInfo = await _step1_IdentifyItem(config, originalImageBase64, enhancedImageBase64);

  // Step 2: 日期解析
  final dateInfo = await _step2_ParseDates(config, originalImageBase64, enhancedImageBase64, today);

  // Step 3: 逻辑验证
  final validatedInfo = await _step3_ValidateDates(config, dateInfo, today);

  // Step 4: 智能推算
  final finalResult = _step4_CalculateExpiry(validatedInfo, itemInfo, today);

  return finalResult;
}
```

- [ ] **Step 4: 实现 Step 1 - 物品识别**

```dart
// lib/services/ai_service.dart
// 在 AIService 类中添加

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
```

- [ ] **Step 5: 实现 Step 2 - 日期解析**

```dart
// lib/services/ai_service.dart
// 在 AIService 类中添加

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
```

- [ ] **Step 6: 实现 Step 3 - 逻辑验证**

```dart
// lib/services/ai_service.dart
// 在 AIService 类中添加

/// Step 3: 逻辑验证
Future<DateValidationResult> _step3_ValidateDates(
  AIConfig config,
  DateParsingResult dateInfo,
  String today,
) async {
  final todayDate = DateTime.parse(today);
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
```

- [ ] **Step 7: 实现 Step 4 - 智能推算**

```dart
// lib/services/ai_service.dart
// 在 AIService 类中添加

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
```

- [ ] **Step 8: 添加辅助方法**

```dart
// lib/services/ai_service.dart
// 在 AIService 类中添加

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
```

- [ ] **Step 9: 提交**

```bash
git add lib/services/ai_service.dart
git commit -m "feat: 重构 AI 服务，添加结构化 Agent 工作流

- Step 1: 物品识别
- Step 2: 日期解析（支持纯数字喷码）
- Step 3: 逻辑验证
- Step 4: 智能推算

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>"
```

---

### Task 9: 集成预处理和 Agent 到 AIInputPage

**Files:**
- Modify: `lib/pages/ai_input_page.dart`

- [ ] **Step 1: 导入预处理服务**

```dart
// lib/pages/ai_input_page.dart 导入部分添加
import '../services/image_preprocessing_service.dart';
```

- [ ] **Step 2: 添加预处理服务实例**

```dart
// lib/pages/ai_input_page.dart
// 在 _AIInputPageState 类中添加

final ImagePreprocessingService _preprocessingService = ImagePreprocessingService();
```

- [ ] **Step 3: 修改 _handlePhotoRecognition 方法，集成预处理和 Agent**

```dart
// lib/pages/ai_input_page.dart
// 替换 _handlePhotoRecognition 方法中的 AI 调用部分

/// 拍照识别
void _handlePhotoRecognition() async {
  final config = await _checkAIConfig();
  if (config == null) return;

  // 选择图片来源
  final source = await showModalBottomSheet<ImageSource>(
    context: context,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.camera_alt),
            title: const Text('拍照'),
            onTap: () => Navigator.pop(context, ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library),
            title: const Text('从相册选择'),
            onTap: () => Navigator.pop(context, ImageSource.gallery),
          ),
        ],
      ),
    ),
  );

  if (source == null) return;

  setState(() {
    _isLoading = true;
    _loadingText = '正在获取图片...';
  });

  String? selectedImagePath;

  try {
    // 获取图片
    final XFile? image = await _imagePicker.pickImage(
      source: source,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );

    if (image == null) {
      setState(() => _isLoading = false);
      return;
    }

    selectedImagePath = image.path;

    setState(() => _loadingText = '正在预处理图片...');

    // 图片预处理
    final preprocessed = await _preprocessingService.preprocess(File(image.path));
    final originalBase64 = _preprocessingService.toBase64(preprocessed.original);
    final enhancedBase64 = _preprocessingService.toBase64(preprocessed.enhanced);

    setState(() => _loadingText = 'AI 正在识别...');

    // 调用 Agent 工作流识别
    final result = await _aiService.recognizeImageWithAgent(
      config: config,
      originalImageBase64: originalBase64,
      enhancedImageBase64: enhancedBase64,
    );

    setState(() => _isLoading = false);

    // 跳转到预填充表单页面
    if (mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => ItemEditPage(
            prefilledData: PrefilledData(
              name: result.name,
              category: result.category,
              brand: result.brand,
              specification: result.specification,
              expiryDate: result.expiryDate,
              purchaseDate: result.purchaseDate,
              aiConfidence: result.confidence,
              dateVisible: result.dateVisible,
              dateLocationHint: result.dateLocationHint,
              expiryInfoSource: result.expiryInfoSource,
              imageUrl: selectedImagePath,
            ),
          ),
        ),
      );
    }
  } catch (e) {
    setState(() => _isLoading = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('识别失败: $e')),
      );
    }
  }
}
```

- [ ] **Step 4: 验证完整流程**

运行应用，测试：
1. 拍照识别淡色喷码包装
2. 确认日期识别准确
3. 确认图片自动加载

- [ ] **Step 5: 提交**

```bash
git add lib/pages/ai_input_page.dart
git commit -m "feat: 集成图片预处理和 Agent 工作流到 AIInputPage

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>"
```

---

### Task 10: 最终验证与清理

**Files:**
- Multiple

- [ ] **Step 1: 运行 Flutter 分析**

```bash
cd H:/code/food_app
flutter analyze
```

预期：无错误，可有少量警告

- [ ] **Step 2: 运行应用完整测试**

测试项目：
1. 深色模式下应用显示正常（浅色主题）
2. 日期选择器显示中文
3. AI 识别淡色喷码包装，能正确识别日期
4. AI 识别图片自动加载到编辑页
5. 保存物品后图片正确存储

- [ ] **Step 3: 提交最终版本**

```bash
git add .
git commit -m "chore: 完成 AI 识别增强与体验优化

- fix: 暂时禁用深色模式
- feat: 中文日期选择器
- feat: AI 图片自动加载
- feat: 图片预处理服务
- feat: 结构化 Agent 工作流

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>"
```

---

## 验收标准

- [ ] 应用在系统深色模式下显示正常（强制浅色主题）
- [ ] 日期选择器显示中文界面
- [ ] AI 能正确识别纯数字喷码日期（如 20260325）
- [ ] AI 能结合保质期文字推算过期日期
- [ ] AI 识别的图片自动加载为物品产品图
- [ ] 淡色喷码图片经过预处理后识别率提升
