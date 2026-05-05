import 'package:flutter/material.dart';
import '../models/item.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import '../theme/spacing.dart';
import 'quantity_selector.dart';

/// 消耗面板回调
typedef ConsumeCallback = void Function(int quantity);

/// 消耗面板底部弹出组件
class ConsumeBottomSheet extends StatefulWidget {
  /// 物品信息
  final Item item;

  /// 确认消耗回调
  final ConsumeCallback onConfirm;

  const ConsumeBottomSheet({
    super.key,
    required this.item,
    required this.onConfirm,
  });

  /// 显示消耗面板
  static Future<void> show({
    required BuildContext context,
    required Item item,
    required ConsumeCallback onConfirm,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ConsumeBottomSheet(
        item: item,
        onConfirm: onConfirm,
      ),
    );
  }

  @override
  State<ConsumeBottomSheet> createState() => _ConsumeBottomSheetState();
}

class _ConsumeBottomSheetState extends State<ConsumeBottomSheet> {
  late int _quantity;

  @override
  void initState() {
    super.initState();
    _quantity = 1;
  }

  void _onQuantityChanged(int value) {
    setState(() {
      _quantity = value;
    });
  }

  void _onConfirm() {
    Navigator.pop(context);
    widget.onConfirm(_quantity);
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.lg),
        ),
      ),
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 顶部拖动条
          Container(
            margin: const EdgeInsets.only(top: AppSpacing.sm),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // 标题栏
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                Text(
                  '消耗数量',
                  style: AppTypography.titleLg.copyWith(
                    color: AppColors.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Icon(
                    Icons.close,
                    size: 24,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // 物品信息和数量选择
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 物品名称和剩余数量
                Text(
                  '${widget.item.name}（剩余 ${widget.item.quantity} ${widget.item.unit}）',
                  style: AppTypography.bodyBase.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // 数量选择器
                Center(
                  child: QuantitySelector(
                    initialValue: 1,
                    maxValue: widget.item.quantity,
                    minValue: 1,
                    unit: widget.item.unit,
                    onChanged: _onQuantityChanged,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          // 确认按钮
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _quantity > 0 ? _onConfirm : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.onPrimary,
                  disabledBackgroundColor: AppColors.surfaceContainer,
                  disabledForegroundColor: AppColors.onSurfaceVariant,
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  shape: RoundedRectangleBorder(
                    borderRadius: AppRadius.medium,
                  ),
                ),
                child: const Text('确认消耗'),
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }
}
