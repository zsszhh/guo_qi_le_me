---
name: 语音录入功能改造
description: 按住录音交互 + 波形动画反馈 + 提示词优化提升识别准确率
type: project
---

# 语音录入功能改造设计

## 背景

现有语音录入功能使用 `speech_to_text` 插件，采用点击开始、自动停止的交互方式。用户反馈希望改为更直观的"按住录音"交互，并优化提示词提升中文识别准确率。

## 目标

1. 改造交互方式：按住录音、松开结束
2. 增加视觉反馈：录音波形动画
3. 优化提示词：提升大模型纠错能力

## 设计详情

### 一、录音按钮组件（VoiceRecordButton）

#### 1.1 状态定义

```dart
enum VoiceRecordState {
  idle,        // 空闲，等待按下
  recording,   // 录音中
  cancelling,  // 上滑取消中
  processing,  // 处理中（识别+解析）
}
```

#### 1.2 交互流程

```
用户动作                组件状态            系统响应
─────────────────────────────────────────────────────
按下按钮        →    recording        → 开始录音 + 震动反馈
保持按住        →    recording        → 显示音量波形
上滑超过80px    →    cancelling       → 显示取消提示 + 红色遮罩
下滑/回位       →    recording        → 恢复录音状态
松开（正常）    →    processing       → 结束录音 + 语音识别
松开（取消区）  →    idle             → 取消录音 + 提示已取消
识别完成        →    idle             → 跳转编辑页
```

#### 1.3 视觉设计

**空闲状态：**
- 圆角胶囊按钮
- 图标 + 双行文字（语音录入 / Voice Input）
- 背景色：`surfaceContainerHigh`

**录音状态：**
- 背景变为 `primary` 色带透明度
- 显示红色录音指示器 + 动画
- 音量波形动画（5条柱状，根据音量实时变化）
- 底部提示"上滑取消"

**取消状态：**
- 背景变为 `error` 色
- 显示取消图标 + 文字
- 波形停止

**处理状态：**
- 显示 loading 指示器
- 文字"正在识别..."

### 二、手势检测实现

```dart
GestureDetector(
  onLongPressStart: _onRecordStart,
  onLongPressMoveUpdate: _onRecordMove,
  onLongPressEnd: _onRecordEnd,
  child: _buildButton(),
)
```

**关键参数：**
- 取消阈值：垂直上滑 80px
- 最短录音时长：0.5 秒（防止误触）
- 最大录音时长：60 秒

### 三、波形动画实现

使用 `AnimationController` + `ValueListenableBuilder`：

```dart
// 音量级别 0-1，来自 speech_to_text 的回调
ValueNotifier<double> _volumeLevel = ValueNotifier(0);

// 波形显示
List<double> _waveformBars = [0, 0, 0, 0, 0]; // 5条柱

// 动画更新
void _updateWaveform(double volume) {
  setState(() {
    _waveformBars.removeAt(0);
    _waveformBars.add(volume);
  });
}
```

**视觉效果：**
- 5 条垂直柱状
- 高度根据音量实时变化
- 颜色渐变：从中心到边缘透明度递减

### 四、提示词优化

#### 4.1 新增纠错规则

```
【语音纠错规则】
由于语音识别可能存在同音字错误，请根据上下文智能纠错：

1. 品牌名纠错：
   - "乐世/乐事/勒是" → 乐事（薯片品牌）
   - "康帅傅" → 康师傅
   - "奥利奥/奥利澳" → 奥利奥
   - "特浓苏" → 特仑苏
   - "养乐多/养乐朵" → 养乐多

2. 商品名推断：
   - 根据用户描述的商品特征推断可能的正确名称
   - 例如："薯片"、"牛奶"、"酸奶" 等类别关键词

3. 同音字处理：
   - 结合商品类别判断最可能的汉字组合
   - 不确定时保留多个可能性，置信度调整

4. 用户输入不完整时：
   - 尽量补充合理信息
   - 没提到的字段用默认值
```

#### 4.2 示例场景

用户说："乐世薯片原味大包"
识别结果可能为："乐世薯片原味大包"
大模型输出：
```json
{
  "name": "乐事薯片",
  "category": "食品",
  "brand": "乐事",
  "specification": "原味大包",
  "confidence": 0.9
}
```

### 五、文件结构

```
lib/
├── widgets/
│   └── voice_record_button.dart    # 新增：录音按钮组件
├── pages/
│   └── ai_input_page.dart          # 修改：替换语音按钮
└── services/
    └── ai_service.dart             # 修改：优化提示词
```

### 六、依赖

现有依赖无需新增：
- `speech_to_text` - 已集成
- `flutter/material.dart` - 动画组件

### 七、测试要点

1. **交互测试**
   - 按下立即开始录音
   - 松开正确结束
   - 上滑取消生效
   - 短按（<0.5s）提示录音太短

2. **波形测试**
   - 音量变化反映到波形
   - 动画流畅无卡顿

3. **识别测试**
   - 常见品牌名纠错
   - 模糊输入合理推断

## 实现计划

见后续 implementation plan。
