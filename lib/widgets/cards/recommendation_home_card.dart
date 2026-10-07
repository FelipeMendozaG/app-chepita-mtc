import 'package:flutter/material.dart';

import '../../models/driving_recommendation.dart';
import '../../screens/recommendation_detail_screen.dart';
import '../../services/recommendation_service.dart';
import '../../services/storage_service.dart';
import '../../theme/app_theme.dart';

class RecommendationHomeCard extends StatefulWidget {
  const RecommendationHomeCard({super.key});

  @override
  State<RecommendationHomeCard> createState() => _RecommendationHomeCardState();
}

class _RecommendationHomeCardState extends State<RecommendationHomeCard> {
  final RecommendationService _service = RecommendationService();
  bool _isLoading = true;
  DrivingRecommendation? _recommendation;

  @override
  void initState() {
    super.initState();
    _loadRecommendation();
  }

  Future<void> _loadRecommendation() async {
    final token = await StorageService().getToken();

    if (!mounted) {
      return;
    }

    if (token == null || token.isEmpty) {
      setState(() {
        _isLoading = false;
        _recommendation = null;
      });
      return;
    }

    try {
      final recommendation = await _service.fetchRecommendation(token: token);

      if (!mounted) {
        return;
      }

      setState(() {
        _recommendation = recommendation;
        _isLoading = false;
      });
    } on RecommendationAuthException {
      if (!mounted) {
        return;
      }

      setState(() {
        _recommendation = null;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _recommendation = null;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_recommendation == null) {
      return const SizedBox.shrink();
    }

    final category = _recommendation!.category;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) =>
                  RecommendationDetailScreen(recommendation: _recommendation!),
            ),
          );
        },
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.lg),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            color: AppColors.surface,
            boxShadow: AppShadows.soft,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primary.withValues(alpha: 0.08),
                AppColors.infoSoftBg.withValues(alpha: 0.6),
              ],
            ),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: const Icon(
                  Icons.lightbulb_outline,
                  size: 28,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if ((category ?? '').trim().isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                        child: Text(
                          category!,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    Text(
                      _recommendation!.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      _recommendation!.content,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12.5,
                        height: 1.4,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(left: AppSpacing.sm, top: 6),
                child: Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const _RecommendationShimmerSkeleton();
  }
}

class _RecommendationShimmerSkeleton extends StatefulWidget {
  const _RecommendationShimmerSkeleton();

  @override
  State<_RecommendationShimmerSkeleton> createState() =>
      _RecommendationShimmerSkeletonState();
}

class _RecommendationShimmerSkeletonState
    extends State<_RecommendationShimmerSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildShimmerBox({
    required double height,
    double? width,
    double borderRadius = AppRadius.sm,
  }) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final opacity = 0.40 + (_animation.value * 0.45);
        return Container(
          height: height,
          width: width,
          decoration: BoxDecoration(
            color: AppColors.border.withValues(alpha: opacity),
            borderRadius: BorderRadius.circular(borderRadius),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        color: AppColors.surface,
        boxShadow: AppShadows.soft,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildShimmerBox(
            width: 52,
            height: 52,
            borderRadius: AppRadius.md,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildShimmerBox(
                  width: 80,
                  height: 10,
                  borderRadius: 4,
                ),
                const SizedBox(height: AppSpacing.sm),
                _buildShimmerBox(
                  width: double.infinity,
                  height: 14,
                  borderRadius: 4,
                ),
                const SizedBox(height: AppSpacing.xs),
                _buildShimmerBox(
                  width: 180,
                  height: 14,
                  borderRadius: 4,
                ),
                const SizedBox(height: AppSpacing.sm),
                _buildShimmerBox(
                  width: double.infinity,
                  height: 11,
                  borderRadius: 4,
                ),
                const SizedBox(height: AppSpacing.xs),
                _buildShimmerBox(
                  width: 140,
                  height: 11,
                  borderRadius: 4,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
