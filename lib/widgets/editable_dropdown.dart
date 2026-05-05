import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import '../theme/spacing.dart';
import '../models/custom_option.dart';
import '../services/custom_option_service.dart';

/// 可编辑下拉选择器
class EditableDropdown extends StatefulWidget {
  final String label;
  final String? value;
  final CustomOptionType type;
  final String? category;  // 用于子分类关联分类
  final List<String> presetOptions;
  final void Function(String?) onChanged;
  final String? Function(String?)? validator;

  const EditableDropdown({
    super.key,
    required this.label,
    this.value,
    required this.type,
    this.category,
    this.presetOptions = const [],
    required this.onChanged,
    this.validator,
  });

  @override
  State<EditableDropdown> createState() => _EditableDropdownState();
}

class _EditableDropdownState extends State<EditableDropdown> {
  final CustomOptionService _optionService = CustomOptionService();
  List<String> _options = [];
  Set<String> _customOptionIds = {};  // 存储自定义选项的 ID
  bool _isLoading = true;
  final _newOptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadOptions();
  }

  @override
  void didUpdateWidget(EditableDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 当分类变化时重新加载选项（用于子分类）
    if (oldWidget.category != widget.category) {
      _loadOptions();
    }
  }

  @override
  void dispose() {
    _newOptionController.dispose();
    super.dispose();
  }

  Future<void> _loadOptions() async {
    setState(() => _isLoading = true);

    // 获取完整选项（预设 + 自定义）
    final allOptions = await _optionService.getOptions(
      widget.type,
      category: widget.category,
    );
    
    // 获取自定义选项的 ID
    final customOptions = await _getCustomOptions();
    final customIds = <String>{};
    for (final option in customOptions) {
      customIds.add(option.id);
    }

    setState(() {
      _options = allOptions;
      _customOptionIds = customIds;
      _isLoading = false;
    });
  }

  Future<List<CustomOption>> _getCustomOptions() async {
    return await _optionService.getCustomOptions(
      widget.type,
      category: widget.category,
    );
  }

  Future<void> _addNewOption() async {
    final value = _newOptionController.text.trim();
    if (value.isEmpty) return;

    // 检查是否已存在
    if (_options.contains(value)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('"$value" 已存在')),
        );
      }
      return;
    }

    // 添加到数据库
    await _optionService.addOption(
      type: widget.type,
      category: widget.category,
      value: value,
    );

    _newOptionController.clear();

    await _loadOptions();

    // 选中新添加的选项
    widget.onChanged(value);
  }

  Future<void> _deleteOption(String optionValue) async {
    // 查找对应的自定义选项
    final customOptions = await _getCustomOptions();
    final targetOption = customOptions.firstWhere(
      (o) => o.value == optionValue,
      orElse: () => throw Exception('选项不存在'),
    );

    await _optionService.deleteOption(targetOption.id);

    // 如果删除的是当前选中的值，清空选择
    if (widget.value == optionValue) {
      widget.onChanged(null);
    }

    await _loadOptions();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('已删除 "$optionValue"')),
      );
    }
  }

  void _showOptionsSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        maxChildSize: 0.8,
        minChildSize: 0.3,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            // 标题栏
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  Text(
                    '选择${widget.type.label}',
                    style: AppTypography.titleLg.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('取消'),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // 选项列表
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: _options.length + 1,  // +1 for add new
                itemBuilder: (context, index) {
                  if (index == _options.length) {
                    // 添加新选项
                    return ListTile(
                      leading: Icon(Icons.add, color: AppColors.primary),
                      title: Text(
                        '添加新${widget.type.label}',
                        style: TextStyle(color: AppColors.primary),
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        _showAddDialog();
                      },
                    );
                  }

                  final option = _options[index];
                  final isPreset = widget.presetOptions.contains(option);
                  final isSelected = widget.value == option;

                  return ListTile(
                    leading: isSelected
                        ? Icon(Icons.check, color: AppColors.primary)
                        : const SizedBox(width: 24),
                    title: Text(option),
                    trailing: isPreset
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () {
                              Navigator.pop(context);
                              _showDeleteConfirm(option);
                            },
                          ),
                    onTap: () {
                      Navigator.pop(context);
                      widget.onChanged(option);
                      _optionService.incrementUsage(
                        option,
                        widget.type,
                        category: widget.category,
                      );
                    },
                    onLongPress: isPreset
                        ? null
                        : () {
                            Navigator.pop(context);
                            _showDeleteConfirm(option);
                          },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('添加${widget.type.label}'),
        content: TextField(
          controller: _newOptionController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: '输入新的${widget.type.label}',
          ),
          onSubmitted: (_) {
            Navigator.of(context).pop();
            _addNewOption();
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _addNewOption();
            },
            child: const Text('添加'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirm(String option) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除 "$option" 吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteOption(option);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        height: 56,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final displayValue = _options.contains(widget.value) ? widget.value : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: _showOptionsSheet,
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: widget.label,
              suffixIcon: const Icon(Icons.arrow_drop_down),
            ),
            child: Text(
              displayValue ?? '请选择',
              style: displayValue != null
                  ? AppTypography.bodyBase
                  : AppTypography.bodyBase.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
            ),
          ),
        ),
        // 隐藏的 validator
        if (widget.validator != null)
          TextFormField(
            initialValue: widget.value,
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
              isDense: true,
            ),
            style: const TextStyle(fontSize: 0, height: 0),
            validator: widget.validator,
            enabled: false,
          ),
      ],
    );
  }
}
