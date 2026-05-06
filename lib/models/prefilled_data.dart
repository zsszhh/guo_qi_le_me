// lib/models/prefilled_data.dart

/// 预填充数据（用于 AI 识别结果）
class PrefilledData {
  final String? name;
  final String? category;
  final String? brand;
  final String? specification;
  final DateTime? purchaseDate;
  final DateTime? expiryDate;
  final double? aiConfidence;
  final bool dateVisible;
  final String? dateLocationHint;
  final String expiryInfoSource;
  final String? imageUrl;

  const PrefilledData({
    this.name,
    this.category,
    this.brand,
    this.specification,
    this.purchaseDate,
    this.expiryDate,
    this.aiConfidence,
    this.dateVisible = true,
    this.dateLocationHint,
    this.expiryInfoSource = '标签显示',
    this.imageUrl,
  });
}
