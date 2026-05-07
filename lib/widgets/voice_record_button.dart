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
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('语音初始化失败: ${error.errorMsg}')),
          );
        }
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
              style: AppTypography.labelCaps.copyWith(
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
      localeId: 'zh_CN',
      listenOptions: stt.SpeechListenOptions(
        partialResults: true,
      ),
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

    if (!mounted) return;

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
