import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import '../theme/spacing.dart';
import '../widgets/photo_recognition_button.dart';
import '../widgets/recent_items_list.dart';
import '../widgets/voice_record_button.dart';
import '../providers/item_provider.dart';
import '../models/item.dart';
import '../models/ai_config.dart';
import '../services/ai_service.dart';
import '../services/database_service.dart';
import '../services/image_preprocessing_service.dart';
import '../models/prefilled_data.dart';
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
  final ImagePreprocessingService _preprocessingService = ImagePreprocessingService();

  @override
  Widget build(BuildContext context) {
    final recentItemsAsync = ref.watch(recentItemsProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text(
          '添加物品',
          style: AppTypography.headlineMd.copyWith(
            color: AppColors.onSurface,
          ),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 标题区域
                _buildHeader(),
                const SizedBox(height: AppSpacing.xl),

                // 居中的拍照识别按钮
                PhotoRecognitionButton(
                  onTap: () => _handlePhotoRecognition(),
                  isLoading: _isLoading,
                ),
                const SizedBox(height: AppSpacing.xl),

                // 语音录入按钮
                _buildVoiceButton(),
                const SizedBox(height: AppSpacing.xl),

                // 最近添加的物品
                recentItemsAsync.when(
                  data: (items) => _buildRecentItems(items),
                  loading: () => const SizedBox.shrink(),
                  error: (error, stackTrace) => const SizedBox.shrink(),
                ),

                // 手动录入链接
                _buildManualEntryLink(),
              ],
            ),
          ),

          // 加载指示器
          if (_isLoading)
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.3),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          _loadingText,
                          style: AppTypography.bodyBase,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// 构建标题区域
  Widget _buildHeader() {
    return Column(
      children: [
        Text(
          '快速添加物品',
          style: AppTypography.titleLg.copyWith(
            color: AppColors.onSurface,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          '拍照或语音录入，让AI自动识别物品信息',
          style: AppTypography.bodySm.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  /// 构建语音录入按钮
  Widget _buildVoiceButton() {
    return Center(
      child: VoiceRecordButton(
        disabled: _isLoading,
        onRecordComplete: (text) => _handleVoiceRecordComplete(text),
      ),
    );
  }

  /// 构建最近物品区域
  Widget _buildRecentItems(List<Item> items) {
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        RecentItemsList(
          items: items,
          onTap: (item) => _handleRecentItemTap(item),
        ),
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }

  /// 构建手动录入链接
  Widget _buildManualEntryLink() {
    return TextButton.icon(
      onPressed: _isLoading ? null : () => _handleManualInput(),
      icon: const Icon(Icons.edit, size: 18),
      label: const Text('手动录入'),
      style: TextButton.styleFrom(
        foregroundColor: AppColors.onSurfaceVariant,
      ),
    );
  }

  /// 处理最近物品点击
  void _handleRecentItemTap(Item item) {
    // 跳转到编辑页面，预填充数据
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ItemEditPage(
          prefilledData: PrefilledData(
            name: item.name,
            category: item.category,
            brand: item.brand,
            specification: item.specification,
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

      // 保存图片路径用于后续传递
      final selectedImagePath = image.path;

      setState(() => _loadingText = '正在预处理图片...');

      // 图片预处理
      final preprocessed = await _preprocessingService.preprocess(File(selectedImagePath));
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

  void _handleManualInput() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const ItemEditPage(),
      ),
    );
  }

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
}
