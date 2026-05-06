import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import '../theme/spacing.dart';

/// 大圆形拍照识别按钮
class PhotoRecognitionButton extends StatelessWidget {
  final VoidCallback onTap;
  final bool isLoading;

  const PhotoRecognitionButton({
    super.key,
    required this.onTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        width: 224,
        height: 224,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primaryContainer,
              AppColors.primaryFixed,
            ],
          ),
          border: Border.all(
            color: AppColors.surfaceContainerLow,
            width: 6,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF4ADE80).withValues(alpha: 0.6),
              blurRadius: 48,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // 光晕叠加层
            Container(
              width: 224,
              height: 224,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.2),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(),
              ),
            ),
            // 内容
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isLoading)
                  const SizedBox(
                    width: 64,
                    height: 64,
                    child: CircularProgressIndicator(
                      color: AppColors.onPrimaryContainer,
                      strokeWidth: 3,
                    ),
                  )
                else
                  const Icon(
                    Icons.photo_camera,
                    size: 64,
                    color: AppColors.onPrimaryContainer,
                  ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  '拍照识别',
                  style: AppTypography.titleLg.copyWith(
                    color: AppColors.onPrimaryContainer,
                  ),
                ),
                Text(
                  '📸 拍照识别',
                  style: AppTypography.bodySm.copyWith(
                    color: AppColors.onPrimaryContainer.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
