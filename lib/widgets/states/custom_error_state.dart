import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../buttons/primary_button.dart';

/// Error state with descriptive icon, message and an integrated retry button.
class CustomErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final String retryLabel;

  const CustomErrorState({
    super.key,
    required this.message,
    required this.onRetry,
    this.retryLabel = 'Reintentar',
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.dangerSoftBg,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline,
                size: 48,
                color: AppColors.danger,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, color: AppColors.textMuted),
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: 180,
              child: PrimaryButton(
                label: retryLabel,
                icon: Icons.refresh,
                onPressed: onRetry,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
