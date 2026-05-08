import 'package:flutter/material.dart';
import '../models/item.dart';
import '../models/ai_config.dart';
import '../models/ai_analysis_cache.dart';
import '../services/ai_service.dart';
import '../services/database_service.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import '../theme/spacing.dart';
import '../utils/constants.dart';

/// AI保质期分析卡片
class AIAnalysisCard extends StatefulWidget {
  final Item item;
  final AIConfig? aiConfig;

  const AIAnalysisCard({
    super.key,
    required this.item,
    this.aiConfig,
  });

  @override
  State<AIAnalysisCard> createState() => _AIAnalysisCardState();
}

class _AIAnalysisCardState extends State<AIAnalysisCard> {
  String? _analysis;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadAnalysis();
  }

  Future<void> _loadAnalysis() async {
    final cacheKey = AIAnalysisCache.generateKey(
      widget.item.category,
      widget.item.subCategory,
      widget.item.openedDate != null,
    );

    // 先查缓存
    final dbService = DatabaseService();
    final cached = await dbService.getAIAnalysisCache(cacheKey);

    if (cached != null) {
      setState(() {
        _analysis = cached.analysisText;
      });
      return;
    }

    // 没有缓存，检查是否有AI配置
    if (widget.aiConfig == null) {
      setState(() {
        _analysis = _getDefaultAnalysis();
      });
      return;
    }

    // 调用AI
    setState(() {
      _isLoading = true;
    });

    try {
      final aiService = AIService();
      final daysRemaining = widget.item.expiryDate.difference(DateTime.now()).inDays;

      final result = await aiService.analyzeShelfLife(
        config: widget.aiConfig!,
        name: widget.item.name,
        category: widget.item.category,
        subCategory: widget.item.subCategory,
        isOpened: widget.item.openedDate != null,
        daysRemaining: daysRemaining,
      );

      // 保存缓存
      final cache = AIAnalysisCache(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        cacheKey: cacheKey,
        analysisText: result.analysis,
        createdAt: DateTime.now(),
      );
      await dbService.saveAIAnalysisCache(cache);

      setState(() {
        _analysis = result.analysis;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _analysis = _getDefaultAnalysis();
        _isLoading = false;
      });
    }
  }

  String _getDefaultAnalysis() {
    final isOpened = widget.item.openedDate != null;
    final daysRemaining = widget.item.expiryDate.difference(DateTime.now()).inDays;

    if (daysRemaining < 0) {
      return '此物品已过期，建议不要继续使用。';
    }

    String tip = '';
    if (widget.item.category == '食品') {
      tip = isOpened
          ? '开封后请尽快食用，建议冷藏保存。'
          : '请按照包装说明妥善保存，注意保质期。';
    } else if (widget.item.category == '药品') {
      tip = isOpened
          ? '开封后保质期可能缩短，请参照药品说明书。'
          : '请置于阴凉干燥处保存，避免阳光直射。';
    } else {
      tip = '请按照产品说明妥善保存。';
    }

    if (daysRemaining <= AppConstants.urgentDaysThreshold) {
      tip += ' 剩余天数较少，建议优先使用。';
    }

    return tip;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Stack(
        children: [
          // 右上角光晕装饰
          Positioned(
            top: -16,
            right: -16,
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.1),
              ),
            ),
          ),
          // 内容
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 图标
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primaryContainer,
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: AppColors.onPrimaryContainer,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              // 文字
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI保质期分析',
                      style: AppTypography.titleLg.copyWith(
                        color: AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    if (_isLoading)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            SizedBox(width: AppSpacing.sm),
                            Text('正在分析...'),
                          ],
                        ),
                      )
                    else
                      Text(
                        _analysis ?? '',
                        style: AppTypography.bodyBase.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
