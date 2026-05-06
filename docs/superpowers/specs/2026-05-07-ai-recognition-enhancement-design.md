# AI识别增强与体验优化设计文档

**日期**：2026-05-07
**状态**：待实施
**优先级**：高

---

## 一、背景与问题

用户在真机测试中发现以下问题：

1. **深色模式显示异常**：添加物品页面在深色模式下，文字变白但背景未变黑，导致文字不可见
2. **日期选择器英文显示**：日期选择器显示英文，国内用户阅读不便
3. **AI 识别不够智能**：包装上只有生产日期和保质期文字时，AI 无法正确推算过期日期（如"保质期9个月"配合底部喷码"20260325"）
4. **AI 识别图片未自动加载**：AI 识别后的照片应该自动成为物品产品图，但目前未实现
5. **喷码识别困难**：包装喷码颜色淡，AI 难以准确识别

---

## 二、解决方案概览

| 问题 | 解决方案 | 复杂度 |
|------|----------|--------|
| 深色模式异常 | 暂时禁用深色模式 | 低 |
| 日期选择器英文 | 使用 flutter_datetime_picker_plus | 中 |
| AI 识别不智能 | 结构化 Agent 工作流 | 高 |
| 图片未自动加载 | 传递图片路径到编辑页 | 低 |
| 喷码识别困难 | 图片预处理（对比度增强+锐化） | 中 |

---

## 三、详细设计

### 3.1 禁用深色模式

**文件**：`lib/app.dart`

**改动**：
```dart
// 修改前
themeMode: ThemeMode.system,

// 修改后
themeMode: ThemeMode.light,
```

**说明**：暂时禁用深色模式，后续如有需求再进行全面改造。

---

### 3.2 日期选择器中文化

**依赖**：`flutter_datetime_picker_plus: ^3.0.0`

**文件**：`lib/pages/item_edit_page.dart`

**改动**：
```dart
Future<void> _selectDate({
  bool isPurchaseDate = false,
  bool isExpiryDate = false,
  bool isOpenedDate = false,
}) async {
  DateTime initialDate;
  if (isPurchaseDate) {
    initialDate = _purchaseDate;
  } else if (isExpiryDate) {
    initialDate = _expiryDate;
  } else if (isOpenedDate) {
    initialDate = _openedDate ?? DateTime.now();
  } else {
    return;
  }

  // 使用 flutter_datetime_picker_plus
  final picked = await showDatePicker(
    context: context,
    initialDate: initialDate,
    firstDate: DateTime(2020),
    lastDate: DateTime(2030),
    locale: const Locale('zh', 'CN'),  // 中文显示
  );

  // ... 其余逻辑不变
}
```

**备选方案**：如需更丰富的选择器样式，可使用 `flutter_datetime_picker_plus` 的 `DatePicker.showPicker` 方法。

---

### 3.3 AI 识别增强 - 结构化 Agent 工作流

#### 3.3.1 工作流设计

```
┌─────────────────────────────────────────────────────────────┐
│                    AI Agent 工作流                           │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  Step 1: 物品识别                                           │
│    输入：图片（原图 + 增强版）                               │
│    输出：名称、分类、品牌、规格                              │
│    提示词：识别物品基本信息                                  │
│                                                             │
│                          ↓                                  │
│                                                             │
│  Step 2: 日期格式解析                                       │
│    输入：图片 + Step 1 结果                                  │
│    输出：所有识别到的日期信息                                │
│    提示词：                                                  │
│    - 扫描所有数字和日期格式                                  │
│    - 识别：标准日期(2024-01-01)、中文日期、纯数字(20260325)  │
│    - 标注每个日期的类型和位置                                │
│                                                             │
│                          ↓                                  │
│                                                             │
│  Step 3: 逻辑一致性验证                                     │
│    输入：Step 2 结果 + 当前日期                              │
│    输出：验证后的日期信息 + 置信度                           │
│    验证规则：                                                │
│    - 生产日期 < 当前日期？                                   │
│    - 过期日期 > 当前日期？                                   │
│    - 生产日期 < 过期日期？                                   │
│    - 数字日期类型判断（结合保质期文字）                       │
│                                                             │
│                          ↓                                  │
│                                                             │
│  Step 4: 智能推算                                           │
│    输入：Step 3 结果 + 保质期文字                            │
│    输出：最终过期日期                                        │
│    规则：                                                    │
│    - 有保质期文字 → 生产日期 + 保质期 = 过期日期              │
│    - 无保质期文字 → 根据分类给默认值                         │
│                                                             │
│                          ↓                                  │
│                                                             │
│  Step 5: 最终输出                                           │
│    输出：结构化结果                                          │
│    {                                                        │
│      name, category, brand, specification,                  │
│      productionDate, shelfLife, expiryDate,                 │
│      expiryInfoSource, confidence,                          │
│      dateLocationHint                                       │
│    }                                                        │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

#### 3.3.2 提示词设计

**Step 1 - 物品识别提示词**：
```
你是物品识别助手。请识别图片中的物品基本信息。

【识别目标】
- 名称（必填）
- 分类：食品/药品/化妆品/日用品/其他
- 品牌（如有）
- 规格（如有）

【返回格式】JSON：
{
  "name": "物品名称",
  "category": "分类",
  "brand": "品牌",
  "specification": "规格"
}
```

**Step 2 - 日期解析提示词**：
```
你是日期解析专家。请仔细扫描图片中的所有日期相关信息。

【日期格式说明】
1. 标准格式：2024-01-01、2024/01/01
2. 中文格式：2024年1月1日
3. 纯数字格式：20260325（YYYYMMDD，常见于喷码）

【特别注意】
- 喷码通常在包装底部、封口处、瓶盖边缘
- 喷码颜色可能较淡
- 单独的数字通常是生产日期

【返回格式】JSON：
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
```

**Step 3 - 验证提示词**：
```
你是日期逻辑验证专家。请验证以下日期信息的合理性。

【当前日期】{today}

【识别到的日期】
{dates_from_step2}

【验证规则】
1. 生产日期应早于当前日期
2. 过期日期应晚于当前日期
3. 如有"保质期X个月"文字，结合推算

【返回格式】JSON：
{
  "production_date": "YYYY-MM-DD",
  "expiry_date": "YYYY-MM-DD",
  "validation_passed": true,
  "confidence": 0.95,
  "notes": "验证说明"
}
```

#### 3.3.3 代码结构

**新增类**：
```dart
/// AI Agent 工作流服务
class AIAgentWorkflow {
  final AIService _aiService;

  /// 执行完整识别流程
  Future<AIRecognitionResult> recognize({
    required AIConfig config,
    required String originalImageBase64,
    required String enhancedImageBase64,
  }) async {
    // Step 1: 物品识别
    final itemInfo = await _step1_IdentifyItem(config, originalImageBase64, enhancedImageBase64);

    // Step 2: 日期解析
    final dateInfo = await _step2_ParseDates(config, originalImageBase64, enhancedImageBase64, itemInfo);

    // Step 3: 逻辑验证
    final validatedInfo = await _step3_ValidateDates(config, dateInfo);

    // Step 4: 智能推算
    final finalResult = _step4_CalculateExpiry(validatedInfo, itemInfo);

    // Step 5: 返回结果
    return finalResult;
  }
}
```

---

### 3.4 图片预处理

**新增文件**：`lib/services/image_preprocessing_service.dart`

**依赖**：`image: ^4.0.0`

**处理流程**：
```dart
class ImagePreprocessingService {
  /// 预处理图片，生成增强版本
  Future<Uint8List> enhanceImage(Uint8List originalBytes) async {
    final image = img.decodeImage(originalBytes);
    if (image == null) throw Exception('无法解码图片');

    // 1. 对比度增强 (+30%)
    var enhanced = img.adjustColor(image, contrast: 1.3);

    // 2. 锐化处理
    enhanced = img.convolution(enhanced, filter: [
      [0, -1, 0],
      [-1, 5, -1],
      [0, -1, 0]
    ]);

    // 3. 自适应亮度调整
    enhanced = img.adjustColor(enhanced, brightness: 0.1);

    return Uint8List.fromList(img.encodeJpg(enhanced, quality: 90));
  }

  /// 生成双版本图片（原图 + 增强版）
  Future<PreprocessedImages> preprocess(File imageFile) async {
    final originalBytes = await imageFile.readAsBytes();
    final enhancedBytes = await enhanceImage(originalBytes);

    return PreprocessedImages(
      original: originalBytes,
      enhanced: enhancedBytes,
    );
  }
}

class PreprocessedImages {
  final Uint8List original;
  final Uint8List enhanced;

  PreprocessedImages({required this.original, required this.enhanced});
}
```

---

### 3.5 AI 识别图片自动加载

**改造文件**：`lib/pages/ai_input_page.dart`

**改动点**：
1. 识别成功后，将图片路径添加到跳转参数
2. 新增 `PrefilledData` 的 `imageUrl` 字段

```dart
// AIInputPage 中识别成功后
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => ItemEditPage(
      prefilledData: PrefilledData(
        name: result.name,
        category: result.category,
        brand: result.brand,
        specification: result.specification,
        expiryDate: result.expiryDate,
        aiConfidence: result.confidence,
        dateVisible: result.dateVisible,
        dateLocationHint: result.dateLocationHint,
        expiryInfoSource: result.expiryInfoSource,
        imageUrl: _selectedImage?.path,  // 新增：传递图片路径
      ),
    ),
  ),
);
```

**改造文件**：`lib/pages/item_edit_page.dart`

**改动点**：
```dart
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
  final String? imageUrl;  // 新增

  const PrefilledData({
    // ... 其他字段
    this.imageUrl,
  });
}

// _applyPrefilledData() 中添加
if (data.imageUrl != null) {
  _imageUrl = data.imageUrl;
  _selectedImage = File(data.imageUrl!);
}
```

---

## 四、文件改动清单

| 文件 | 改动类型 | 改动内容 |
|------|----------|----------|
| `pubspec.yaml` | 修改 | 添加 flutter_datetime_picker_plus、image 依赖 |
| `lib/app.dart` | 修改 | 禁用深色模式 |
| `lib/pages/item_edit_page.dart` | 修改 | 日期选择器替换、自动加载 AI 图片 |
| `lib/pages/ai_input_page.dart` | 修改 | 传递图片路径、集成预处理和 Agent |
| `lib/services/ai_service.dart` | 重构 | Agent 工作流、优化提示词 |
| `lib/services/image_preprocessing_service.dart` | 新增 | 图片预处理服务 |
| `lib/models/prefilled_data.dart` | 新增/修改 | PrefilledData 数据类（或内联修改） |

---

## 五、实施顺序

1. **Phase 1**：基础修复（低风险）
   - 禁用深色模式
   - 添加依赖

2. **Phase 2**：体验优化（中风险）
   - 日期选择器替换
   - AI 图片自动加载

3. **Phase 3**：AI 增强（高风险，核心改动）
   - 图片预处理服务
   - Agent 工作流重构
   - 提示词优化

---

## 六、风险与注意事项

1. **AI 调用次数增加**：Agent 工作流需要多次调用 AI API，可能增加成本和耗时
   - 缓解：可考虑将部分步骤合并为单次调用

2. **图片处理耗时**：预处理会增加约 0.5-1 秒延迟
   - 缓解：显示处理进度提示

3. **兼容性**：纯数字日期解析可能有误判
   - 缓解：提供置信度指标，低于阈值时提示用户确认

---

## 七、验收标准

1. ✅ 应用在深色模式下显示正常（已禁用）
2. ✅ 日期选择器显示中文
3. ✅ AI 能正确识别纯数字喷码日期并推算过期时间
4. ✅ AI 识别的图片自动加载为物品产品图
5. ✅ 淡色喷码图片经过预处理后识别率提升
