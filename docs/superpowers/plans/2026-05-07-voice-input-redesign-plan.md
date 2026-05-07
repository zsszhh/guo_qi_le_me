# 语音录入功能改造实现计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 改造语音录入交互为按住录音模式，增加波形动画反馈，优化提示词提升识别准确率

**Architecture:** 创建独立的 VoiceRecordButton 组件封装录音交互逻辑，使用 GestureDetector 长按手势检测，speech_to_text 提供音量回调实现波形动画，优化 AI 提示词增加品牌纠错规则

**Tech Stack:** Flutter, speech_to_text, GestureDetector, AnimationController

---

## 文件结构

```
lib/
├── widgets/
│   └── voice_record_button.dart    # 新建：录音按钮组件
├── pages/
│   └── ai_input_page.dart          # 修改：替换语音按钮调用
└── services/
    └── ai_service.dart             # 修改：优化语音解析提示词
```

---

### Task 1: 创建 VoiceRecordButton 组件基础结构

**Files:**
- Create: `lib/widgets/voice_record_button.dart`

- [ ] **Step 1: 创建组件文件和状态定义**

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../theme/colors.dart';
import '../theme/typography.dart';
import '../theme/spacing.dart';

/// 录音状态
enum VoiceRecordState {
  idle,        // 空闲，等待按下
  recording,   // 录音中
  cancelling,  // 上滑取消中
  processing,  // 处理中
}

/// 语音录音按钮
class VoiceRecordButton extends StatefulWidget {
  /// 录音完成回调，返回识别文本
  final void Function(String text) onRecordComplete;
  
  /// 是否禁用
  final bool disabled;

  const VoiceRecordButton({
    super.key,
    required this.onRecordComplete,
    this.disabled = false,
  });

  @override
  State<VoiceRecordButton> createState() => _VoiceRecordButtonState();
}

class _VoiceRecordButtonState extends State<VoiceRecordButton> 
    with SingleTickerProviderStateMixin {
  
  VoiceRecordState _state = VoiceRecordState.idle;
  
  // 语音识别
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _speechAvailable = false;
  String _recognizedText = '';
  
  // 录音开始时间
  DateTime? _recordStartTime;
  
  // 波形数据（5条柱）
  final List<double> _waveformBars = [0, 0, 0, 0, 0];
  
  // 取消阈值（像素）
  static const double _cancelThreshold = 80;
  
  // 最短录音时长（秒）
  static const double _minRecordDuration = 0.5;

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    _speechAvailable = await _speech.initialize(
      onError: (error) {
        _setState(VoiceRecordState.idle);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('语音初始化失败: ${error.errorMsg}')),
        );
      },
    );
  }

  void _setState(VoiceRecordState newState) {
    if (mounted) {
      setState(() {
        _state = newState;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPressStart: widget.disabled ? null : _onRecordStart,
      onLongPressMoveUpdate: widget.disabled ? null : _onRecordMove,
      onLongPressEnd: widget.disabled ? null : _onRecordEnd,
      child: _buildButton(),
    );
  }

  Widget _buildButton() {
    // 根据状态构建不同的按钮外观
    switch (_state) {
      case VoiceRecordState.idle:
        return _buildIdleButton();
      case VoiceRecordState.recording:
        return _buildRecordingButton();
      case VoiceRecordState.cancelling:
        return _buildCancellingButton();
      case VoiceRecordState.processing:
        return _buildProcessingButton();
    }
  }

  Widget _buildIdleButton() {
    return Container(
      height: 64,
      constraints: const BoxConstraints(maxWidth: 320),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.5),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.mic,
              color: AppColors.primary,
              size: 24,
            ),
            const SizedBox(width: AppSpacing.sm),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '语音录入',
                  style: AppTypography.bodyBase.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.onSurface,
                  ),
                ),
                Text(
                  'Voice Input',
                  style: AppTypography.bodySm.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordingButton() {
    return Container(
      height: 80,
      constraints: const BoxConstraints(maxWidth: 320),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.5),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.2),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 录音指示器
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: AppColors.error,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  '录音中...',
                  style: AppTypography.bodyBase.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            // 波形动画
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 100),
                  width: 4,
                  height: 8 + _waveformBars[index] * 24,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(
                      alpha: 0.4 + _waveformBars[index] * 0.4,
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                );
              }),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '上滑取消',
              style: AppTypography.bodyXs.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCancellingButton() {
    return Container(
      height: 80,
      constraints: const BoxConstraints(maxWidth: 320),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(
          color: AppColors.error.withValues(alpha: 0.5),
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.cancel,
                  color: AppColors.error,
                  size: 20,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  '松开取消',
                  style: AppTypography.bodyBase.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.error,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Icon(
              Icons.arrow_upward,
              color: AppColors.error.withValues(alpha: 0.6),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProcessingButton() {
    return Container(
      height: 64,
      constraints: const BoxConstraints(maxWidth: 320),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(AppColors.primary),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              '正在识别...',
              style: AppTypography.bodyBase.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onRecordStart(LongPressStartDetails details) {
    if (!_speechAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('语音识别不可用')),
      );
      return;
    }

    // 震动反馈
    HapticFeedback.mediumImpact();

    _recordStartTime = DateTime.now();
    _recognizedText = '';
    _setState(VoiceRecordState.recording);

    // 开始录音
    _speech.listen(
      onResult: (result) {
        _recognizedText = result.recognizedWords;
        if (result.finalResult) {
          _speech.stop();
        }
      },
      onSoundLevelChange: (level) {
        // 更新波形
        _updateWaveform(level);
      },
      listenFor: const Duration(seconds: 60),
      pauseFor: const Duration(seconds: 3),
      partialResults: true,
      localeId: 'zh_CN',
    );
  }

  void _onRecordMove(LongPressMoveUpdateDetails details) {
    // 检测上滑距离
    final deltaY = details.localPosition.dy;
    
    // 注意：向上滑动时 deltaY 为负值
    if (deltaY < -_cancelThreshold) {
      if (_state == VoiceRecordState.recording) {
        _setState(VoiceRecordState.cancelling);
        HapticFeedback.lightImpact();
      }
    } else {
      if (_state == VoiceRecordState.cancelling) {
        _setState(VoiceRecordState.recording);
      }
    }
  }

  void _onRecordEnd(LongPressEndDetails details) async {
    await _speech.stop();

    // 检查是否取消
    final deltaY = details.localPosition.dy;
    if (deltaY < -_cancelThreshold || _state == VoiceRecordState.cancelling) {
      _setState(VoiceRecordState.idle);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('已取消'),
          duration: Duration(seconds: 1),
        ),
      );
      return;
    }

    // 检查录音时长
    final duration = DateTime.now().difference(_recordStartTime!).inMilliseconds / 1000;
    if (duration < _minRecordDuration) {
      _setState(VoiceRecordState.idle);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('录音时间太短'),
          duration: Duration(seconds: 1),
        ),
      );
      return;
    }

    // 处理识别结果
    _setState(VoiceRecordState.processing);

    if (_recognizedText.isEmpty) {
      _setState(VoiceRecordState.idle);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('未识别到语音内容')),
      );
      return;
    }

    // 回调
    widget.onRecordComplete(_recognizedText);
    _setState(VoiceRecordState.idle);
  }

  void _updateWaveform(double level) {
    if (!mounted) return;
    
    // 将音量级别 (-160 到 0 dB) 映射到 0-1
    final normalizedLevel = ((level + 160) / 160).clamp(0.0, 1.0);
    
    setState(() {
      _waveformBars.removeAt(0);
      _waveformBars.add(normalizedLevel);
    });
  }
}
```

- [ ] **Step 2: 检查语法并提交组件**

运行: `flutter analyze lib/widgets/voice_record_button.dart`
预期: 无错误

```bash
git add lib/widgets/voice_record_button.dart
git commit -m "feat: 创建 VoiceRecordButton 按住录音组件

- 支持按住录音、松开结束交互
- 实时波形动画反馈
- 上滑取消功能
- 最短录音时长检测

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>"
```

---

### Task 2: 修改 AIInputPage 使用新组件

**Files:**
- Modify: `lib/pages/ai_input_page.dart`

- [ ] **Step 1: 导入新组件并修改 _buildVoiceButton 方法**

找到 `_buildVoiceButton` 方法（约第142-205行），替换为：

```dart
/// 构建语音录入按钮
Widget _buildVoiceButton() {
  return Center(
    child: VoiceRecordButton(
      disabled: _isLoading,
      onRecordComplete: (text) => _handleVoiceRecordComplete(text),
    ),
  );
}
```

- [ ] **Step 2: 添加新的语音处理方法**

在 `_handleVoiceInput` 方法后添加新方法：

```dart
/// 处理语音录音完成
void _handleVoiceRecordComplete(String recognizedText) async {
  final config = await _checkAIConfig();
  if (config == null) return;

  setState(() {
    _isLoading = true;
    _loadingText = 'AI 正在解析...';
  });

  try {
    // 调用AI解析
    final parseResult = await _aiService.parseVoice(
      config: config,
      text: recognizedText,
    );

    setState(() => _isLoading = false);

    // 跳转到预填充表单页面
    if (mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => ItemEditPage(
            prefilledData: PrefilledData(
              name: parseResult.name,
              category: parseResult.category,
              brand: parseResult.brand,
              specification: parseResult.specification,
              expiryDate: parseResult.expiryDate,
              purchaseDate: parseResult.purchaseDate,
              aiConfidence: parseResult.confidence,
              dateVisible: parseResult.dateVisible,
              dateLocationHint: parseResult.dateLocationHint,
              expiryInfoSource: parseResult.expiryInfoSource,
            ),
          ),
        ),
      );
    }
  } catch (e) {
    setState(() => _isLoading = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('语音解析失败: $e')),
      );
    }
  }
}
```

- [ ] **Step 3: 添加导入语句**

在文件顶部添加导入：

```dart
import '../widgets/voice_record_button.dart';
```

- [ ] **Step 4: 删除旧的 _handleVoiceInput 方法**

删除原有的 `_handleVoiceInput` 方法（约第377-479行），因为逻辑已移至 `_handleVoiceRecordComplete`。

- [ ] **Step 5: 验证并提交**

运行: `flutter analyze lib/pages/ai_input_page.dart`
预期: 无错误

```bash
git add lib/pages/ai_input_page.dart
git commit -m "feat: AIInputPage 使用 VoiceRecordButton 组件

- 替换原有点击录音为按住录音
- 简化语音处理逻辑

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>"
```

---

### Task 3: 优化语音解析提示词

**Files:**
- Modify: `lib/services/ai_service.dart`

- [ ] **Step 1: 替换 _getDefaultVoicePrompt 方法**

找到 `_getDefaultVoicePrompt` 方法（约第647-688行），替换为：

```dart
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
   - 听到"薯片/薯条/脆片" → 可能是零食类
   - 听到"牛奶/纯牛奶/鲜奶" → 可能是乳制品
   - 听到"酸奶/优酸乳" → 可能是酸奶
   - 听到"酱油/耗油/醋" → 可能是调味品

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
```

- [ ] **Step 2: 验证并提交**

运行: `flutter analyze lib/services/ai_service.dart`
预期: 无错误

```bash
git add lib/services/ai_service.dart
git commit -m "feat: 优化语音解析提示词

- 增加常见品牌名纠错规则
- 商品类别推断
- 同音字智能处理
- 更丰富的日期表达识别

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>"
```

---

### Task 4: 整体验证

- [ ] **Step 1: 运行 Flutter 分析**

运行: `flutter analyze`
预期: No issues found

- [ ] **Step 2: 测试编译**

运行: `flutter build apk --debug` 或 `flutter run`
预期: 编译成功

- [ ] **Step 3: 最终提交（如有遗漏）**

```bash
git status
# 如有未提交文件
git add -A
git commit -m "chore: 完善语音录入功能改造

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>"
```

---

## 测试清单

实现完成后，手动验证以下功能：

1. **按住录音交互**
   - [ ] 长按按钮开始录音，有震动反馈
   - [ ] 录音时显示波形动画
   - [ ] 松开结束录音
   - [ ] 上滑超过阈值显示取消状态
   - [ ] 松开在取消区正确取消
   - [ ] 录音时间 <0.5s 提示太短

2. **波形动画**
   - [ ] 说话时波形随音量变化
   - [ ] 动画流畅无卡顿

3. **AI 解析**
   - [ ] 常见品牌名正确纠错
   - [ ] 模糊输入合理推断
   - [ ] 正确跳转到编辑页面

---

## 风险点

1. **Android 权限**：确保 `AndroidManifest.xml` 已包含录音权限
2. **iOS 权限**：确保 `Info.plist` 已包含 `NSSpeechRecognitionUsageDescription`
3. **Windows 平台**：speech_to_text 在 Windows 上支持有限，可能体验较差
