import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/attempt.dart';
import '../providers/attempt_provider.dart';
import '../theme/app_theme.dart';
import '../utils/date_formatter.dart';
import '../widgets/cards/app_card.dart';
import '../widgets/cards/status_badge.dart';
import '../widgets/states/custom_empty_state.dart';
import '../widgets/states/custom_error_state.dart';
import '../widgets/states/custom_loading_state.dart';
import 'attempt_detail_screen.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final attemptsAsync = ref.watch(attemptsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Mi Historial de Simulacros')),
      body: attemptsAsync.when(
        loading: () => const CustomLoadingState(),
        error: (error, stackTrace) => CustomErrorState(
          message: 'Error: $error',
          onRetry: () => ref.invalidate(attemptsProvider),
        ),
        data: (attempts) {
          if (attempts.isEmpty) {
            return const CustomEmptyState(
              icon: Icons.history,
              title: 'No hay simulacros realizados',
              subtitle: 'Realiza tu primer simulacro para ver tu historial',
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(attemptsProvider);
              await ref.read(attemptsProvider.future);
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(AppSpacing.lg),
              itemCount: attempts.length,
              itemBuilder: (context, index) {
                final attempt = attempts[index];
                return _AttemptCard(
                  attempt: attempt,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            AttemptDetailScreen(attemptId: attempt.id),
                      ),
                    );
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _AttemptCard extends StatelessWidget {
  final Attempt attempt;
  final VoidCallback onTap;

  const _AttemptCard({required this.attempt, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isFinished = attempt.finishedAt != null;
    final score = attempt.score;
    final approved = attempt.approved;

    final StatusBadgeType badgeType;
    final String badgeLabel;
    if (!isFinished) {
      badgeType = StatusBadgeType.warning;
      badgeLabel = 'EN PROGRESO';
    } else if (approved) {
      badgeType = StatusBadgeType.success;
      badgeLabel = 'APROBADO';
    } else {
      badgeType = StatusBadgeType.danger;
      badgeLabel = 'DESAPROBADO';
    }

    return AppCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Intento #${attempt.id}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              StatusBadge(label: badgeLabel, type: badgeType),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              const Icon(
                Icons.calendar_today,
                size: 16,
                color: AppColors.textMuted,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  AppDateFormatter.friendly(attempt.startedAt),
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          const Divider(height: 1),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'PUNTAJE',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textMuted,
                        letterSpacing: 1,
                      ),
                    ),
                    Text(
                      score.toStringAsFixed(2),
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              _StatItem(
                icon: Icons.check_circle,
                value: '${attempt.correctAnswers}',
                color: AppColors.success,
              ),
              const SizedBox(width: AppSpacing.lg),
              _StatItem(
                icon: Icons.cancel,
                value: '${attempt.wrongAnswers}',
                color: AppColors.danger,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                'Ver detalle',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              Icon(
                Icons.chevron_right,
                size: 18,
                color: Theme.of(context).colorScheme.primary,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final Color color;

  const _StatItem({
    required this.icon,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 22, color: color),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
