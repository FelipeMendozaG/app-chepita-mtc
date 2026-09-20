import 'package:flutter/material.dart';

import '../models/driving_recommendation.dart';
import '../services/recommendation_service.dart';
import '../theme/app_theme.dart';

class RecommendationDetailScreen extends StatelessWidget {
  final DrivingRecommendation recommendation;

  const RecommendationDetailScreen({super.key, required this.recommendation});

  @override
  Widget build(BuildContext context) {
    final category = recommendation.category;
    final imageUri = RecommendationService.resolveImageUri(
      recommendation.imageUrl,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Consejo del día')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (imageUri != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  child: SizedBox(
                    width: double.infinity,
                    height: 220,
                    child: Image.network(
                      imageUri.toString(),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: AppColors.infoSoftBg,
                          child: const Center(
                            child: Icon(
                              Icons.lightbulb_outline,
                              size: 42,
                              color: AppColors.primary,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                )
              else
                Container(
                  width: double.infinity,
                  height: 180,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.lightbulb_outline,
                      size: 48,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              const SizedBox(height: AppSpacing.lg),
              if ((category ?? '').trim().isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    category!,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              const SizedBox(height: AppSpacing.md),
              Text(
                recommendation.title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                recommendation.content,
                style: const TextStyle(
                  fontSize: 16,
                  height: 1.7,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
