import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../theme/colors.dart';
import '../theme/typography.dart';
import '../theme/spacing.dart';
import '../utils/constants.dart';
import '../providers/item_provider.dart';
import '../models/item.dart';
import '../models/custom_option.dart';
import '../widgets/editable_dropdown.dart';
import '../services/product_image_service.dart';

/// 预填充数据（用于 AI 识别结果）
class PrefilledData {
  final String? name;
  final String? category;
  final String? brand;
  final String? specification;
  final DateTime? purchaseDate;
  final DateTime? expiryDate;
  final double? aiConfidence;

  const PrefilledData({
    this.name,
    this.category,
    this.brand,
    this.specification,
    this.purchaseDate,
    this.expiryDate,
    this.aiConfidence,
  });
}

/// 物品编辑页面
class ItemEditPage extends ConsumerStatefulWidget {
  final String? itemId;
  final PrefilledData? prefilledData;

  const ItemEditPage({super.key, this.itemId, this.prefilledData});

  @override
  ConsumerState<ItemEditPage> createState() => _ItemEditPageState();
}

class _ItemEditPageState extends ConsumerState<ItemEditPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _brandController = TextEditingController();
  final _specificationController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');
  final _notesController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();

  String _category = PresetCategories.food;  // 改为字符串支持自定义分类
  String? _subCategory;
  DateTime _purchaseDate = DateTime.now();
  DateTime _expiryDate = DateTime.now().add(const Duration(days: 7));
  DateTime? _openedDate;
  String? _location;
  String _unit = '个';
  bool _isSaving = false;
  bool _isLoading = false;
  String? _imageUrl;
  File? _selectedImage;

  final ProductImageService _productImageService = ProductImageService();
  bool _showSimilarItemsHint = false;
  List<Item> _similarItems = [];

  bool get _isEditing => widget.itemId != null;
  bool get _hasPrefilledData => widget.prefilledData != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _loadItem();
    } else if (_hasPrefilledData) {
      _applyPrefilledData();
    }
  }

  void _applyPrefilledData() {
    final data = widget.prefilledData!;
    _nameController.text = data.name ?? '';
    _brandController.text = data.brand ?? '';
    _specificationController.text = data.specification ?? '';
    if (data.category != null) {
      _category = data.category!;
    }
    if (data.purchaseDate != null) {
      _purchaseDate = data.purchaseDate!;
    }
    if (data.expiryDate != null) {
      _expiryDate = data.expiryDate!;
    }
  }

  void _loadItem() {
    final item = ref.read(itemByIdProvider(widget.itemId!));
    if (item != null) {
      _nameController.text = item.name;
      _brandController.text = item.brand ?? '';
      _specificationController.text = item.specification ?? '';
      _quantityController.text = item.quantity.toString();
      _notesController.text = item.notes ?? '';
      _category = item.category;
      _subCategory = item.subCategory;
      _purchaseDate = item.purchaseDate;
      _expiryDate = item.expiryDate;
      _openedDate = item.openedDate;
      _location = item.location;
      _unit = item.unit;
      _imageUrl = item.imageUrl;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _brandController.dispose();
    _specificationController.dispose();
    _quantityController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text(
          _isEditing ? '编辑物品' : '添加物品',
          style: AppTypography.headlineMd.copyWith(
            color: AppColors.onSurface,
          ),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
        actions: [
          _isSaving
              ? const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : TextButton(
                  onPressed: _saveItem,
                  child: Text(
                    '保存',
                    style: AppTypography.bodyBase.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [
                  // 图片区域
                  _buildImageSection(),
                  const SizedBox(height: AppSpacing.lg),

                  // 基本信息
                  _buildSectionTitle('基本信息'),
                  const SizedBox(height: AppSpacing.sm),

            // 物品名称
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: '物品名称 *',
                hintText: '例如：牛奶、感冒药',
              ),
              textInputAction: TextInputAction.next,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '请输入物品名称';
                }
                return null;
              },
              onChanged: (value) {
                // 名称变化时隐藏提示
                if (_showSimilarItemsHint) {
                  setState(() {
                    _showSimilarItemsHint = false;
                  });
                }
              },
              onFieldSubmitted: (_) {
                _checkSimilarItems();
              },
            ),
            const SizedBox(height: AppSpacing.md),

            // 相似物品提示
            if (_showSimilarItemsHint && _similarItems.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: InkWell(
                  onTap: _showSimilarItemsDialog,
                  borderRadius: AppRadius.small,
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer,
                      borderRadius: AppRadius.small,
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.lightbulb_outline, size: 20, color: AppColors.primary),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            '发现 ${_similarItems.length} 个相似物品，点击复用数据',
                            style: AppTypography.bodySm.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        Icon(Icons.chevron_right, size: 20, color: AppColors.primary),
                      ],
                    ),
                  ),
                ),
              ),

            // 分类选择
            Row(
              children: [
                Expanded(
                  child: EditableDropdown(
                    label: '分类',
                    value: _category,
                    type: CustomOptionType.category,
                    presetOptions: PresetCategories.defaults,
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _category = value;
                          _subCategory = null;
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: EditableDropdown(
                    label: '子分类',
                    value: _subCategory,
                    type: CustomOptionType.subCategory,
                    category: _category,
                    onChanged: (value) {
                      setState(() => _subCategory = value);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // 品牌
            TextFormField(
              controller: _brandController,
              decoration: const InputDecoration(
                labelText: '品牌',
                hintText: '可选',
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // 规格
            TextFormField(
              controller: _specificationController,
              decoration: const InputDecoration(
                labelText: '规格',
                hintText: '例如：500ml、10片装',
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // 日期信息
            _buildSectionTitle('日期信息'),
            const SizedBox(height: AppSpacing.sm),

            // 购买日期
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('购买日期'),
              subtitle: Text(_formatDate(_purchaseDate)),
              trailing: const Icon(Icons.calendar_today),
              onTap: () => _selectDate(isPurchaseDate: true),
            ),
            const Divider(),

            // 过期日期
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('过期日期 *'),
              subtitle: Text(_formatDate(_expiryDate)),
              trailing: const Icon(Icons.calendar_today),
              onTap: () => _selectDate(isExpiryDate: true),
            ),
            const Divider(),

            // 开封日期
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('开封日期'),
              subtitle: Text(_openedDate != null ? _formatDate(_openedDate!) : '未开封'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_openedDate != null)
                    IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        setState(() => _openedDate = null);
                      },
                    ),
                  const Icon(Icons.calendar_today),
                ],
              ),
              onTap: () => _selectDate(isOpenedDate: true),
            ),
            const SizedBox(height: AppSpacing.lg),

            // 数量信息
            _buildSectionTitle('数量信息'),
            const SizedBox(height: AppSpacing.sm),

            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _quantityController,
                    decoration: const InputDecoration(
                      labelText: '数量',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: EditableDropdown(
                    label: '单位',
                    value: _unit,
                    type: CustomOptionType.unit,
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _unit = value);
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            // 存放位置
            _buildSectionTitle('存放位置'),
            const SizedBox(height: AppSpacing.sm),

            EditableDropdown(
              label: '位置',
              value: _location,
              type: CustomOptionType.location,
              category: _category,
              onChanged: (value) {
                setState(() => _location = value);
              },
            ),
            const SizedBox(height: AppSpacing.lg),

            // 备注
            _buildSectionTitle('备注'),
            const SizedBox(height: AppSpacing.sm),

            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: '备注',
                hintText: '其他需要记录的信息',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    final hasImage = _selectedImage != null || _imageUrl != null;

    return Center(
      child: InkWell(
        onTap: _pickImage,
        borderRadius: AppRadius.large,
        child: Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: AppColors.surfaceContainer,
            borderRadius: AppRadius.large,
            border: Border.all(
              color: AppColors.outlineVariant,
              width: 1,
            ),
          ),
          child: hasImage
              ? ClipRRect(
                  borderRadius: AppRadius.large,
                  child: _selectedImage != null
                      ? Image.file(
                          _selectedImage!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _buildPlaceholder(),
                        )
                      : (_imageUrl != null
                          ? Image.file(
                              File(_imageUrl!),
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _buildPlaceholder(),
                            )
                          : _buildPlaceholder()),
                )
              : _buildPlaceholder(),
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.add_photo_alternate_outlined,
          size: 40,
          color: AppColors.onSurfaceVariant,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          '添加图片',
          style: AppTypography.bodySm.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: AppTypography.titleLg.copyWith(
        color: AppColors.onSurface,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> _selectDate({
    bool isPurchaseDate = false,
    bool isExpiryDate = false,
    bool isOpenedDate = false,
  }) async {
    DateTime initialDate;
    if (isPurchaseDate) {
      initialDate = _purchaseDate;
    } else if (isExpiryDate) {
      initialDate = _expiryDate;
    } else if (isOpenedDate) {
      initialDate = _openedDate ?? DateTime.now();
    } else {
      return;
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (picked != null) {
      setState(() {
        if (isPurchaseDate) {
          _purchaseDate = picked;
        } else if (isExpiryDate) {
          _expiryDate = picked;
        } else if (isOpenedDate) {
          _openedDate = picked;
        }
      });
    }
  }

  void _pickImage() async {
    final name = _nameController.text.trim();
    final recommendedImages = await _productImageService.searchProductImages(name);

    // 选择图片来源
    final source = await showModalBottomSheet<_ImageSource>(
      context: context,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 推荐图片区域
            if (recommendedImages.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    Icon(Icons.auto_awesome, size: 20, color: AppColors.primary),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      '推荐图片',
                      style: AppTypography.bodySm.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  itemCount: recommendedImages.length,
                  itemBuilder: (context, index) {
                    final productImage = recommendedImages[index];
                    return GestureDetector(
                      onTap: () {
                        Navigator.pop(context, _ImageSource.recommended(productImage.imagePath));
                      },
                      child: Container(
                        width: 80,
                        margin: const EdgeInsets.only(right: AppSpacing.sm),
                        child: Column(
                          children: [
                            ClipRRect(
                              borderRadius: AppRadius.small,
                              child: Image.file(
                                File(productImage.imagePath),
                                width: 80,
                                height: 60,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  width: 80,
                                  height: 60,
                                  color: AppColors.surfaceContainer,
                                  child: const Icon(Icons.broken_image),
                                ),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              productImage.name,
                              style: AppTypography.labelCaps.copyWith(
                                color: AppColors.onSurfaceVariant,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const Divider(),
            ],
            // 标准选项
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('拍照'),
              onTap: () => Navigator.pop(context, _ImageSource.camera()),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('从相册选择'),
              onTap: () => Navigator.pop(context, _ImageSource.gallery()),
            ),
            if (_selectedImage != null || _imageUrl != null)
              ListTile(
                leading: const Icon(Icons.delete, color: AppColors.error),
                title: const Text('移除图片', style: TextStyle(color: AppColors.error)),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _selectedImage = null;
                    _imageUrl = null;
                  });
                },
              ),
          ],
        ),
      ),
    );

    if (source == null) return;

    if (source.isRecommended) {
      // 复制推荐图片
      final newPath = await _productImageService.copyProductImageForItem(source.path);
      if (newPath != null && mounted) {
        setState(() {
          _selectedImage = File(newPath);
          _imageUrl = newPath;
        });
      }
      return;
    }

    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source.isCamera ? ImageSource.camera : ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 80,
      );

      if (image != null) {
        // 保存图片到应用目录
        final appDir = await getApplicationDocumentsDirectory();
        final imagesDir = Directory('${appDir.path}/item_images');
        if (!await imagesDir.exists()) {
          await imagesDir.create(recursive: true);
        }

        final fileName = '${const Uuid().v4()}${p.extension(image.path)}';
        final savedPath = '${imagesDir.path}/$fileName';
        await File(image.path).copy(savedPath);

        setState(() {
          _selectedImage = File(savedPath);
          _imageUrl = savedPath;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('选择图片失败: $e')),
        );
      }
    }
  }

  void _saveItem() async {
    if (_formKey.currentState!.validate()) {
      if (_isSaving) return;

      setState(() => _isSaving = true);

      try {
        final item = Item(
          id: _isEditing ? widget.itemId! : const Uuid().v4(),
          name: _nameController.text.trim(),
          category: _category,
          subCategory: _subCategory,
          brand: _brandController.text.trim().isEmpty
              ? null : _brandController.text.trim(),
          specification: _specificationController.text.trim().isEmpty
              ? null : _specificationController.text.trim(),
          purchaseDate: _purchaseDate,
          expiryDate: _expiryDate,
          openedDate: _openedDate,
          quantity: int.tryParse(_quantityController.text) ?? 1,
          unit: _unit,
          location: _location,
          notes: _notesController.text.trim().isEmpty
              ? null : _notesController.text.trim(),
          imageUrl: _imageUrl,
          status: ItemStatus.normal,
          createdAt: _isEditing ? DateTime.now() : DateTime.now(),
          updatedAt: DateTime.now(),
        );

        if (_isEditing) {
          await ref.read(itemsProvider.notifier).updateItem(item);
          // 更新产品图片库
          if (_imageUrl != null && _nameController.text.trim().isNotEmpty) {
            await _productImageService.saveProductImage(
              _nameController.text.trim(),
              _imageUrl!,
            );
          }
        } else {
          await ref.read(itemsProvider.notifier).addItem(item);
          // 保存产品图片到产品图库
          if (_imageUrl != null && _nameController.text.trim().isNotEmpty) {
            await _productImageService.saveProductImage(
              _nameController.text.trim(),
              _imageUrl!,
            );
          }
        }

        if (mounted) {
          // 返回到主页（弹出所有路由直到首页）
          Navigator.of(context).popUntil((route) => route.isFirst);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(_isEditing ? '物品已更新' : '物品已添加')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('保存失败: $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isSaving = false);
        }
      }
    }
  }

  /// 检查相似物品
  Future<void> _checkSimilarItems() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    final similarItems = await ref.read(itemsProvider.notifier).searchSimilarItems(name);

    if (similarItems.isNotEmpty && mounted) {
      setState(() {
        _similarItems = similarItems;
        _showSimilarItemsHint = true;
      });
    }
  }

  /// 显示相似物品选择弹窗
  Future<void> _showSimilarItemsDialog() async {
    final selected = await showModalBottomSheet<Item>(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        maxChildSize: 0.8,
        minChildSize: 0.3,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            // 标题
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                children: [
                  Text(
                    '发现相似物品',
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
            // 列表
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                itemCount: _similarItems.length,
                itemBuilder: (context, index) {
                  final item = _similarItems[index];
                  return ListTile(
                    leading: item.imageUrl != null
                        ? ClipRRect(
                            borderRadius: AppRadius.small,
                            child: Image.file(
                              File(item.imageUrl!),
                              width: 48,
                              height: 48,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                width: 48,
                                height: 48,
                                color: AppColors.surfaceContainer,
                                child: const Icon(Icons.image_not_supported),
                              ),
                            ),
                          )
                        : Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppColors.surfaceContainer,
                              borderRadius: AppRadius.small,
                            ),
                            child: const Icon(Icons.inventory_2_outlined),
                          ),
                    title: Text(item.name),
                    subtitle: Text(
                      '${item.category}${item.brand != null ? ' · ${item.brand}' : ''}${item.specification != null ? ' · ${item.specification}' : ''}',
                      style: AppTypography.bodySm.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    onTap: () => Navigator.pop(context, item),
                  );
                },
              ),
            ),
            // 提示
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Text(
                '选择后将自动填充分类、品牌、规格等信息',
                style: AppTypography.bodySm.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );

    if (selected != null && mounted) {
      _fillFromItem(selected);
    }
  }

  /// 从已有物品填充表单
  void _fillFromItem(Item item) {
    setState(() {
      _category = item.category;
      _subCategory = item.subCategory;
      _brandController.text = item.brand ?? '';
      _specificationController.text = item.specification ?? '';
      _unit = item.unit;
      _location = item.location;
      _notesController.text = item.notes ?? '';
      if (item.imageUrl != null) {
        _imageUrl = item.imageUrl;
        _selectedImage = File(item.imageUrl!);
      }
      _showSimilarItemsHint = false;
    });
  }
}

/// 图片来源类型（支持推荐图片）
class _ImageSource {
  final bool isCamera;
  final bool isGallery;
  final bool isRecommended;
  final String path;

  const _ImageSource._({
    this.isCamera = false,
    this.isGallery = false,
    this.isRecommended = false,
    this.path = '',
  });

  factory _ImageSource.camera() => const _ImageSource._(isCamera: true);
  factory _ImageSource.gallery() => const _ImageSource._(isGallery: true);
  factory _ImageSource.recommended(String path) =>
      _ImageSource._(isRecommended: true, path: path);
}
