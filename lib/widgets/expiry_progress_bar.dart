import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';

/// 过期进度条组件
class ExpiryProgressBar extends StatelessWidget {
  final DateTime purchaseDate;
  final DateTime expiryDate;
  final double height;

  const ExpiryProgressBar({
    super.key,
    required this.purchaseDate,
    required this.expiryDate,
    this.height = 4,
  });

  @override
  Widget build(BuildContext context) {
    final progress = _calculateProgress();
    final color = _getProgressColor(progress);

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: AppRadius.small,
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: progress.clamp(0.0, 1.0),
        child: Container(
          decoration: BoxDecoration(
            color: color,
            borderRadius: AppRadius.small,
          ),
        ),
      ),
    );
  }

  double _calculateProgress() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final purchase = DateTime(purchaseDate.year, purchaseDate.month, purchaseDate.day);
    final expiry = DateTime(expiryDate.year, expiryDate.month, expiryDate.day);

    final totalDays = expiry.difference(purchase).inDays;
    final elapsedDays = today.difference(purchase).inDays;

    if (totalDays <= 0) return 1.0;
    return elapsedDays / totalDays;
  }

  Color _getProgressColor(double progress) {
    if (progress >= 1.0) {
      return AppColors.error;
    } else if (progress >= 0.85) {
      return AppColors.error;
    } else if (progress >= 0.75) {
      return AppColors.secondary;
    } else {
      return AppColors.primary;
    }
  }
}
