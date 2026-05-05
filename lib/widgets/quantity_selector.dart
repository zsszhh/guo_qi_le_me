import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import '../theme/spacing.dart';

/// 数量选择器组件
class QuantitySelector extends StatefulWidget {
  /// 初始值
  final int initialValue;

  /// 最大值
  final int maxValue;

  /// 最小值
  final int minValue;

  /// 单位
  final String unit;

  /// 值变化回调
  final ValueChanged<int>? onChanged;

  const QuantitySelector({
    super.key,
    this.initialValue = 1,
    required this.maxValue,
    this.minValue = 1,
    this.unit = '个',
    this.onChanged,
  });

  @override
  State<QuantitySelector> createState() => _QuantitySelectorState();
}

class _QuantitySelectorState extends State<QuantitySelector> {
  late TextEditingController _controller;
  late int _currentValue;

  @override
  void initState() {
    super.initState();
    _currentValue = widget.initialValue.clamp(widget.minValue, widget.maxValue);
    _controller = TextEditingController(text: _currentValue.toString());
  }

  @override
  void didUpdateWidget(QuantitySelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.maxValue != widget.maxValue) {
      // 最大值变化时，确保当前值在有效范围内
      _currentValue = _currentValue.clamp(widget.minValue, widget.maxValue);
      _controller.text = _currentValue.toString();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _decrement() {
    if (_currentValue > widget.minValue) {
      _updateValue(_currentValue - 1);
    }
  }

  void _increment() {
    if (_currentValue < widget.maxValue) {
      _updateValue(_currentValue + 1);
    }
  }

  void _updateValue(int newValue) {
    final clampedValue = newValue.clamp(widget.minValue, widget.maxValue);
    if (clampedValue != _currentValue) {
      setState(() {
        _currentValue = clampedValue;
        _controller.text = _currentValue.toString();
      });
      widget.onChanged?.call(_currentValue);
    }
  }

  void _onSubmitted(String value) {
    final parsed = int.tryParse(value);
    if (parsed != null) {
      _updateValue(parsed);
    } else {
      // 恢复为当前值
      _controller.text = _currentValue.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    final canDecrement = _currentValue > widget.minValue;
    final canIncrement = _currentValue < widget.maxValue;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 减少按钮
        _buildButton(
          icon: Icons.remove,
          onPressed: canDecrement ? _decrement : null,
        ),
        const SizedBox(width: AppSpacing.sm),

        // 数量输入框
        SizedBox(
          width: 60,
          child: TextField(
            controller: _controller,
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
            ],
            onSubmitted: _onSubmitted,
            style: AppTypography.titleLg.copyWith(
              color: AppColors.onSurface,
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: AppRadius.medium,
                borderSide: BorderSide(color: AppColors.outlineVariant),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: AppRadius.medium,
                borderSide: BorderSide(color: AppColors.outlineVariant),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: AppRadius.medium,
                borderSide: BorderSide(color: AppColors.primary, width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.sm,
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),

        // 增加按钮
        _buildButton(
          icon: Icons.add,
          onPressed: canIncrement ? _increment : null,
        ),
        const SizedBox(width: AppSpacing.md),

        // 单位
        Text(
          widget.unit,
          style: AppTypography.bodyBase.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildButton({
    required IconData icon,
    required VoidCallback? onPressed,
  }) {
    final isEnabled = onPressed != null;
    return Material(
      color: isEnabled ? AppColors.surfaceContainer : AppColors.surfaceContainerHighest,
      borderRadius: AppRadius.medium,
      child: InkWell(
        onTap: onPressed,
        borderRadius: AppRadius.medium,
        child: Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          child: Icon(
            icon,
            size: 20,
            color: isEnabled ? AppColors.onSurface : AppColors.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
