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

enum HistoryFilter { all, approved, failed }

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  HistoryFilter _selectedFilter = HistoryFilter.all;

  @override
  Widget build(BuildContext context) {
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

          final approvedCount = attempts.where((a) => a.approved).length;
          final failedCount = attempts.where((a) => !a.approved).length;

          final filteredAttempts = attempts.where((attempt) {
            switch (_selectedFilter) {
              case HistoryFilter.approved:
                return attempt.approved;
              case HistoryFilter.failed:
                return !attempt.approved;
              case HistoryFilter.all:
                return true;
            }
          }).toList();

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(attemptsProvider);
              await ref.read(attemptsProvider.future);
            },
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                _HistoryStatsHeader(attempts: attempts),
                const SizedBox(height: AppSpacing.lg),
                SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<HistoryFilter>(
                    showSelectedIcon: false,
                    segments: [
                      ButtonSegment(
                        value: HistoryFilter.all,
                        label: Text('Todos (${attempts.length})'),
                      ),
                      ButtonSegment(
                        value: HistoryFilter.approved,
                        label: Text(
                          'Aprobados ($approvedCount)',
                          style: TextStyle(
                            color: approvedCount > 0 ? AppColors.success : null,
                            fontWeight:
                                approvedCount > 0 ? FontWeight.bold : null,
                          ),
                        ),
                      ),
                      ButtonSegment(
                        value: HistoryFilter.failed,
                        label: Text(
                          'Desaprobados ($failedCount)',
                          style: TextStyle(
                            color: failedCount > 0 ? AppColors.danger : null,
                            fontWeight:
                                failedCount > 0 ? FontWeight.bold : null,
                          ),
                        ),
                      ),
                    ],
                    selected: {_selectedFilter},
                    onSelectionChanged: (newSelection) {
                      setState(() {
                        _selectedFilter = newSelection.first;
                      });
                    },
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                if (filteredAttempts.isEmpty)
                  CustomEmptyState(
                    icon: _selectedFilter == HistoryFilter.approved
                        ? Icons.emoji_events_outlined
                        : Icons.history,
                    title: _selectedFilter == HistoryFilter.approved
                        ? 'Aún no tienes simulacros aprobados'
                        : 'No hay simulacros para este filtro',
                    subtitle: _selectedFilter == HistoryFilter.approved
                        ? '¡Sigue practicando para alcanzar la meta de 35 aciertos!'
                        : 'Selecciona otro filtro para revisar tus intentos.',
                  )
                else
                  ...filteredAttempts.map(
                    (attempt) => _AttemptCard(
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
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _HistoryStatsHeader extends StatelessWidget {
  final List<Attempt> attempts;

  const _HistoryStatsHeader({required this.attempts});

  @override
  Widget build(BuildContext context) {
    final total = attempts.length;
    final approved = attempts.where((a) => a.approved).length;
    final rate = total > 0 ? (approved / total * 100).toStringAsFixed(0) : '0';
    final bestScore = total > 0
        ? attempts.map((a) => a.score).reduce((a, b) => a > b ? a : b)
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.insights, size: 20, color: AppColors.primary),
              SizedBox(width: AppSpacing.sm),
              Text(
                'Rendimiento Global',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          const Divider(height: 1),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _HeaderMetric(
                  icon: Icons.quiz_outlined,
                  color: AppColors.primary,
                  label: 'Simulacros',
                  value: '$total',
                ),
              ),
              Expanded(
                child: _HeaderMetric(
                  icon: Icons.check_circle_outline,
                  color: AppColors.success,
                  label: 'Aprobados',
                  value: '$approved',
                ),
              ),
              Expanded(
                child: _HeaderMetric(
                  icon: Icons.pie_chart_outline,
                  color: AppColors.info,
                  label: 'Tasa de Éxito',
                  value: '$rate%',
                ),
              ),
              Expanded(
                child: _HeaderMetric(
                  icon: Icons.star_border_rounded,
                  color: AppColors.warning,
                  label: 'Mejor Nota',
                  value: bestScore.toStringAsFixed(0),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeaderMetric extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;

  const _HeaderMetric({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 22, color: color),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
        ),
      ],
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
                      score.toStringAsFixed(0),
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    Text(
                      '${attempt.correctAnswers}/${attempt.totalQuestions} aciertos',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textMuted,
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
