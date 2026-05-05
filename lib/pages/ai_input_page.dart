import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:uuid/uuid.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import '../theme/spacing.dart';
import '../widgets/ai_button.dart';
import '../providers/item_provider.dart';
import '../models/item.dart';
import '../models/ai_config.dart';
import '../models/custom_option.dart';
import '../services/ai_service.dart';
import '../services/database_service.dart';
import '../widgets/editable_dropdown.dart';
import '../utils/constants.dart';
import 'item_edit_page.dart';

/// AI智能录入页面
class AIInputPage extends ConsumerStatefulWidget {
  const AIInputPage({super.key});

  @override
  ConsumerState<AIInputPage> createState() => _AIInputPageState();
}

class _AIInputPageState extends ConsumerState<AIInputPage> {
  bool _isLoading = false;
  String _loadingText = 'AI 正在识别...';
  final ImagePicker _imagePicker = ImagePicker();
  final AIService _aiService = AIService();
  final DatabaseService _dbService = DatabaseService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text(
          'AI 智能录入',
          style: AppTypography.headlineMd.copyWith(
            color: AppColors.onSurface,
          ),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 拍照识别卡片
            _buildInputCard(
              icon: Icons.photo_camera,
              title: '拍照识别',
              subtitle: '拍摄物品包装自动识别信息',
              color: AppColors.primary,
              onTap: () => _handlePhotoRecognition(),
            ),
            const SizedBox(height: AppSpacing.md),

            // 语音录入卡片
            _buildInputCard(
              icon: Icons.mic,
              title: '语音录入',
              subtitle: '说出物品信息自动解析',
              color: AppColors.secondary,
              onTap: () => _handleVoiceInput(),
            ),
            const SizedBox(height: AppSpacing.lg),

            // 分隔线
            Row(
              children: [
                const Expanded(child: Divider()),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  child: Text(
                    '或者',
                    style: AppTypography.bodySm.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ),
                const Expanded(child: Divider()),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            // 手动录入按钮
            AIButton(
              type: AIButtonType.secondary,
              label: '手动录入',
              icon: Icons.edit,
              onPressed: () => _handleManualInput(),
            ),

            // 加载指示器
            if (_isLoading) ...[
              const SizedBox(height: AppSpacing.xl),
              Center(
                child: Column(
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: AppSpacing.md),
                    Text(_loadingText),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInputCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _isLoading ? null : onTap,
        borderRadius: AppRadius.large,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: AppRadius.large,
            border: Border.all(
              color: color.withOpacity(0.3),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: AppRadius.medium,
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.titleLg.copyWith(
                        color: color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      subtitle,
                      style: AppTypography.bodySm.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: color),
            ],
          ),
        ),
      ),
    );
  }

  /// 检查AI配置
  Future<AIConfig?> _checkAIConfig() async {
    final config = await _dbService.getAIConfig();
    if (config == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('请先配置AI服务'),
            action: SnackBarAction(
              label: '去配置',
              onPressed: () {
                Navigator.of(context).pushNamed('/ai-config');
              },
            ),
          ),
        );
      }
      return null;
    }
    return config;
  }

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

  /// 语音录入
  void _handleVoiceInput() async {
    final config = await _checkAIConfig();
    if (config == null) return;

    setState(() {
      _isLoading = true;
      _loadingText = '请说话...';
    });

    try {
      final speech = stt.SpeechToText();
      final available = await speech.initialize(
        onError: (error) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('语音初始化失败: ${error.errorMsg}')),
          );
        },
        onStatus: (status) {
          if (status == 'done' || status == 'notListening') {
            speech.stop();
          }
        },
      );

      if (!available) {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('语音识别不可用')),
          );
        }
        return;
      }

      String recognizedText = '';

      await speech.listen(
        onResult: (result) {
          recognizedText = result.recognizedWords;
          if (result.finalResult) {
            speech.stop();
          }
        },
        listenFor: const Duration(seconds: 10),
        pauseFor: const Duration(seconds: 3),
        partialResults: true,
      );

      // 等待语音识别完成
      await Future.delayed(const Duration(seconds: 3));

      if (recognizedText.isEmpty) {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('未识别到语音内容')),
          );
        }
        return;
      }

      setState(() => _loadingText = 'AI 正在解析...');

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
              ),
            ),
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('语音识别失败: $e')),
        );
      }
    }
  }

  void _handleManualInput() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const ItemEditPage(),
      ),
    );
  }
}
