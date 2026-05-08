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
import '../widgets/message_toast.dart';
import '../providers/item_provider.dart';
import '../models/item.dart';
import '../models/ai_config.dart';
import '../services/ai_service.dart';
import '../services/database_service.dart';
import '../services/image_preprocessing_service.dart';
import '../models/prefilled_data.dart';
import 'item_edit_page.dart';
import 'dart:math' as math;

/// AI智能录入页面
class AIInputPage extends ConsumerStatefulWidget {
  const AIInputPage({super.key});

  @override
  ConsumerState<AIInputPage> createState() => _AIInputPageState();
}

class _AIInputPageState extends ConsumerState<AIInputPage>
    with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  String _loadingText = 'AI 正在识别...';
  String _loadingSubtext = '';
  double _loadingProgress = 0.0;
  final ImagePicker _imagePicker = ImagePicker();
  final AIService _aiService = AIService();
  final DatabaseService _dbService = DatabaseService();
  final ImagePreprocessingService _preprocessingService = ImagePreprocessingService();

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

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
        fit: StackFit.expand,
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

          // 加载指示器 - 全屏遮罩
          if (_isLoading)
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.6),
                child: Center(
                  child: _buildModernLoadingIndicator(),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// 构建现代风格的加载指示器
  Widget _buildModernLoadingIndicator() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.2),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 动态脉冲圆环
          Stack(
            alignment: Alignment.center,
            children: [
              // 外圈脉冲
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Container(
                    width: 80 * _pulseAnimation.value,
                    height: 80 * _pulseAnimation.value,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        width: 2,
                      ),
                    ),
                  );
                },
              ),
              // 中圈
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.5),
                    width: 2,
                  ),
                ),
              ),
              // 内圈旋转
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(seconds: 2),
                builder: (context, value, child) {
                  return Transform.rotate(
                    angle: value * 2 * math.pi,
                    child: CustomPaint(
                      size: const Size(48, 48),
                      painter: _ArcPainter(
                        color: AppColors.primary,
                        strokeWidth: 3,
                      ),
                    ),
                  );
                },
              ),
              // 中心图标
              Icon(
                _getLoadingIcon(),
                size: 24,
                color: AppColors.primary,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          // 主文字
          Text(
            _loadingText,
            style: AppTypography.titleLg.copyWith(
              color: AppColors.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          if (_loadingSubtext.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              _loadingSubtext,
              style: AppTypography.bodySm.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          // 进度条
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: _loadingProgress > 0 ? _loadingProgress : null,
              backgroundColor: AppColors.surfaceVariant,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }

  /// 根据加载状态获取图标
  IconData _getLoadingIcon() {
    if (_loadingText.contains('图片')) return Icons.image;
    if (_loadingText.contains('预处理')) return Icons.auto_fix_high;
    if (_loadingText.contains('识别') || _loadingText.contains('AI')) return Icons.psychology;
    return Icons.hourglass_top;
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
        MessageService.warning(context, '请先配置AI服务');
        // 跳转到AI配置页
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) Navigator.of(context).pushNamed('/ai-config');
        });
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
    if (!mounted) return;
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
      _loadingSubtext = '请稍候';
      _loadingProgress = 0.1;
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

      setState(() {
        _loadingText = '正在预处理图片...';
        _loadingSubtext = '优化图片质量';
        _loadingProgress = 0.3;
      });

      // 图片预处理
      final preprocessed = await _preprocessingService.preprocess(File(selectedImagePath));
      final originalBase64 = _preprocessingService.toBase64(preprocessed.original);
      final enhancedBase64 = _preprocessingService.toBase64(preprocessed.enhanced);

      setState(() {
        _loadingText = 'AI 正在识别...';
        _loadingSubtext = '分析物品信息';
        _loadingProgress = 0.6;
      });

      // 调用 Agent 工作流识别
      final result = await _aiService.recognizeImageWithAgent(
        config: config,
        originalImageBase64: originalBase64,
        enhancedImageBase64: enhancedBase64,
      );

      setState(() {
        _loadingProgress = 1.0;
      });

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
      setState(() {
        _isLoading = false;
        _loadingProgress = 0;
      });
      if (mounted) {
        MessageService.error(context, '识别失败: $e');
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
      _loadingSubtext = '理解语音内容';
      _loadingProgress = 0.3;
    });

    try {
      // 调用AI解析
      setState(() {
        _loadingText = 'AI 正在解析...';
        _loadingSubtext = '理解语音内容';
        _loadingProgress = 0.6;
      });

      final parseResult = await _aiService.parseVoice(
        config: config,
        text: recognizedText,
      );

      setState(() {
        _loadingProgress = 1.0;
      });

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
      setState(() {
        _isLoading = false;
        _loadingProgress = 0;
      });
      if (mounted) {
        MessageService.error(context, '语音解析失败: $e');
      }
    }
  }
}

/// 绘制圆弧的画笔
class _ArcPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;

  _ArcPainter({required this.color, required this.strokeWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromLTWH(
      strokeWidth / 2,
      strokeWidth / 2,
      size.width - strokeWidth,
      size.height - strokeWidth,
    );

    canvas.drawArc(rect, -math.pi / 2, math.pi * 1.5, false, paint);
  }

  @override
  bool shouldRepaint(covariant _ArcPainter oldDelegate) {
    return color != oldDelegate.color || strokeWidth != oldDelegate.strokeWidth;
  }
}
