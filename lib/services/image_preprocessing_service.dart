// lib/services/image_preprocessing_service.dart

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;

/// 预处理后的图片结果
class PreprocessedImages {
  /// 原始图片字节
  final Uint8List original;

  /// 增强后的图片字节
  final Uint8List enhanced;

  const PreprocessedImages({
    required this.original,
    required this.enhanced,
  });
}

/// 图片预处理服务
/// 用于增强图片质量，提高 AI 识别准确率
class ImagePreprocessingService {
  static final ImagePreprocessingService _instance = ImagePreprocessingService._internal();
  factory ImagePreprocessingService() => _instance;
  ImagePreprocessingService._internal();

  /// 预处理图片，生成增强版本
  ///
  /// 处理步骤：
  /// 1. 对比度增强 (+30%)
  /// 2. 锐化处理
  /// 3. 自适应亮度调整
  Future<Uint8List> enhanceImage(Uint8List originalBytes) async {
    final image = img.decodeImage(originalBytes);
    if (image == null) {
      throw Exception('无法解码图片');
    }

    // 1. 对比度增强 (+30%)
    var enhanced = img.adjustColor(image, contrast: 1.3);

    // 2. 锐化处理（使用卷积核）
    enhanced = img.convolution(
      enhanced,
      filter: [
        [0, -1, 0],
        [-1, 5, -1],
        [0, -1, 0]
      ],
    );

    // 3. 自适应亮度调整
    enhanced = img.adjustColor(enhanced, brightness: 0.1);

    // 编码为 JPEG
    return Uint8List.fromList(img.encodeJpg(enhanced, quality: 90));
  }

  /// 生成双版本图片（原图 + 增强版）
  ///
  /// 用于发送给 AI 进行对比识别
  Future<PreprocessedImages> preprocess(File imageFile) async {
    final originalBytes = await imageFile.readAsBytes();
    final enhancedBytes = await enhanceImage(originalBytes);

    return PreprocessedImages(
      original: originalBytes,
      enhanced: enhancedBytes,
    );
  }

  /// 将图片转换为 Base64
  String toBase64(Uint8List bytes) {
    return base64Encode(bytes);
  }
}
