import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import '../theme/spacing.dart';

/// AI智能录入按钮组件
class AIButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String label;
  final IconData icon;
  final bool isLoading;
  final AIButtonType type;

  const AIButton({
    super.key,
    this.onPressed,
    this.label = 'AI 智能录入',
    this.icon = Icons.photo_camera,
    this.isLoading = false,
    this.type = AIButtonType.primary,
  });

  @override
  Widget build(BuildContext context) {
    switch (type) {
      case AIButtonType.primary:
        return _buildPrimaryButton();
      case AIButtonType.secondary:
        return _buildSecondaryButton();
      case AIButtonType.compact:
        return _buildCompactButton();
    }
  }

  Widget _buildPrimaryButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isLoading ? null : onPressed,
        borderRadius: AppRadius.fullBorder,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.lg,
            horizontal: AppSpacing.xl,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primaryContainer,
                AppColors.primaryFixed,
              ],
            ),
            borderRadius: AppRadius.fullBorder,
            border: Border.all(
              color: AppColors.primaryFixed.withOpacity(0.5),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryContainer.withOpacity(0.25),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.onPrimaryContainer,
                        ),
                      ),
                    )
                  : Icon(
                      icon,
                      size: 24,
                      color: AppColors.onPrimaryContainer,
                    ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                label,
                style: AppTypography.titleLg.copyWith(
                  color: AppColors.onPrimaryContainer,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSecondaryButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isLoading ? null : onPressed,
        borderRadius: AppRadius.fullBorder,
        child: Container(
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.md,
            horizontal: AppSpacing.lg,
          ),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerHigh,
            borderRadius: AppRadius.fullBorder,
            border: Border.all(
              color: AppColors.outlineVariant.withOpacity(0.5),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 20,
                color: AppColors.primary,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                label,
                style: AppTypography.bodyBase.copyWith(
                  color: AppColors.onSurface,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactButton() {
    return IconButton(
      onPressed: isLoading ? null : onPressed,
      icon: isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(icon, color: AppColors.primary),
      style: IconButton.styleFrom(
        backgroundColor: AppColors.primaryContainer.withOpacity(0.2),
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.fullBorder,
        ),
      ),
    );
  }
}

enum AIButtonType {
  primary,
  secondary,
  compact,
}
