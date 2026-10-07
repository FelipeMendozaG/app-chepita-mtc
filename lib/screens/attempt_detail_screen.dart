import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/attempt.dart';
import '../providers/attempt_provider.dart';
import '../theme/app_theme.dart';
import '../utils/date_formatter.dart';
import '../widgets/cards/app_card.dart';
import '../widgets/cards/question_explanation_tile.dart';
import '../widgets/cards/question_image_widget.dart';
import '../widgets/cards/status_badge.dart';
import '../widgets/states/custom_empty_state.dart';
import '../widgets/states/custom_error_state.dart';
import '../widgets/states/custom_loading_state.dart';

enum AnswerFilter { all, incorrect, correct }

class AttemptDetailScreen extends ConsumerStatefulWidget {
  final int attemptId;

  const AttemptDetailScreen({super.key, required this.attemptId});

  @override
  ConsumerState<AttemptDetailScreen> createState() =>
      _AttemptDetailScreenState();
}

class _AttemptDetailScreenState extends ConsumerState<AttemptDetailScreen> {
  AnswerFilter _selectedFilter = AnswerFilter.all;

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(attemptDetailProvider(widget.attemptId));

    return Scaffold(
      appBar: AppBar(title: const Text('Detalle del Intento')),
      body: detailAsync.when(
        loading: () => const CustomLoadingState(),
        error: (error, stackTrace) => CustomErrorState(
          message: 'Error: $error',
          onRetry: () => ref.invalidate(attemptDetailProvider(widget.attemptId)),
        ),
        data: (attempt) {
          final wrongCount = attempt.answers.where((a) => !a.isCorrect).length;
          final correctCount = attempt.answers.where((a) => a.isCorrect).length;

          final filteredAnswers = attempt.answers.where((a) {
            switch (_selectedFilter) {
              case AnswerFilter.incorrect:
                return !a.isCorrect;
              case AnswerFilter.correct:
                return a.isCorrect;
              case AnswerFilter.all:
                return true;
            }
          }).toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SummaryCard(attempt: attempt),
                const SizedBox(height: AppSpacing.xl),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Detalle de respuestas',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${filteredAnswers.length} de ${attempt.answers.length}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                // Filtro por estado de respuesta
                if (attempt.answers.isNotEmpty) ...[
                  SizedBox(
                    width: double.infinity,
                    child: SegmentedButton<AnswerFilter>(
                      showSelectedIcon: false,
                      segments: [
                        ButtonSegment(
                          value: AnswerFilter.all,
                          label: Text('Todas (${attempt.answers.length})'),
                        ),
                        ButtonSegment(
                          value: AnswerFilter.incorrect,
                          label: Text(
                            'Incorrectas ($wrongCount)',
                            style: TextStyle(
                              color: wrongCount > 0 ? AppColors.danger : null,
                              fontWeight: wrongCount > 0 ? FontWeight.bold : null,
                            ),
                          ),
                        ),
                        ButtonSegment(
                          value: AnswerFilter.correct,
                          label: Text(
                            'Correctas ($correctCount)',
                            style: TextStyle(
                              color: correctCount > 0 ? AppColors.success : null,
                              fontWeight: correctCount > 0 ? FontWeight.bold : null,
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
                  const SizedBox(height: AppSpacing.md),
                ],
                if (attempt.answers.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'No hay respuestas registradas para este intento',
                        style: TextStyle(
                          fontSize: 16,
                          color: AppColors.textMuted,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                else if (filteredAnswers.isEmpty)
                  CustomEmptyState(
                    icon: _selectedFilter == AnswerFilter.incorrect
                        ? Icons.celebration_outlined
                        : Icons.quiz_outlined,
                    title: _selectedFilter == AnswerFilter.incorrect
                        ? '¡Sin errores en este intento!'
                        : 'No hay respuestas para este filtro',
                    subtitle: _selectedFilter == AnswerFilter.incorrect
                        ? 'Acertaste todas las preguntas registradas.'
                        : 'Selecciona otra categoría para visualizar las preguntas.',
                  )
                else
                  ...filteredAnswers.map((answer) {
                    final originalIndex = attempt.answers.indexOf(answer);
                    return _QuestionDetailCard(
                      number: originalIndex + 1,
                      answer: answer,
                    );
                  }),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final Attempt attempt;

  const _SummaryCard({required this.attempt});

  @override
  Widget build(BuildContext context) {
    final approved = attempt.approved;
    final score = attempt.score;

    return AppCard(
      child: Column(
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
              StatusBadge(
                label: approved ? 'APROBADO' : 'DESAPROBADO',
                type: approved
                    ? StatusBadgeType.success
                    : StatusBadgeType.danger,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                approved ? Icons.verified_outlined : Icons.info_outline,
                size: 14,
                color: approved ? AppColors.success : AppColors.danger,
              ),
              const SizedBox(width: 4),
              Text(
                'Nota mínima MTC: 35 de 40 preguntas',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: approved ? AppColors.success : AppColors.danger,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
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
                  'Inicio: ${AppDateFormatter.friendly(attempt.startedAt)}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              const Icon(Icons.timer, size: 16, color: AppColors.textMuted),
              const SizedBox(width: 6),
              Text(
                'Duración: ${AppDateFormatter.duration(attempt.startedAt, attempt.finishedAt)}',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          const Divider(height: 1),
          const SizedBox(height: AppSpacing.lg),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 2.2,
            children: [
              _DetailStat(
                icon: Icons.check_circle,
                label: 'Correctas',
                value: '${attempt.correctAnswers}',
                color: AppColors.success,
              ),
              _DetailStat(
                icon: Icons.cancel,
                label: 'Incorrectas',
                value: '${attempt.wrongAnswers}',
                color: AppColors.danger,
              ),
              _DetailStat(
                icon: Icons.score,
                label: 'Puntaje',
                value: score.toStringAsFixed(2),
                color: AppColors.primary,
              ),
              _DetailStat(
                icon: Icons.quiz,
                label: 'Preguntas',
                value: '${attempt.totalQuestions}',
                color: AppColors.warning,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DetailStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _DetailStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Icon(icon, size: 20, color: color),
        ),
        const SizedBox(width: AppSpacing.sm),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
          ],
        ),
      ],
    );
  }
}

class _QuestionDetailCard extends StatelessWidget {
  final int number;
  final AttemptAnswer answer;

  const _QuestionDetailCard({required this.number, required this.answer});

  @override
  Widget build(BuildContext context) {
    final isCorrect = answer.isCorrect;
    final question = answer.question;

    return AppCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isCorrect
                      ? AppColors.successSoftBg
                      : AppColors.dangerSoftBg,
                ),
                child: Icon(
                  isCorrect ? Icons.check : Icons.close,
                  size: 18,
                  color: isCorrect ? AppColors.success : AppColors.danger,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Pregunta $number',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              StatusBadge(
                label: isCorrect ? 'Correcta' : 'Incorrecta',
                type: isCorrect
                    ? StatusBadgeType.success
                    : StatusBadgeType.danger,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (question != null) ...[
            Text(
              question.question,
              style: const TextStyle(fontSize: 15, height: 1.4),
            ),
            if (question.imageUrl != null &&
                question.imageUrl!.trim().isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              QuestionImageWidget(imageUrl: question.imageUrl!),
            ],
            const SizedBox(height: AppSpacing.lg),
            const Divider(height: 1),
            const SizedBox(height: AppSpacing.md),
            const Text(
              'Opciones:',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.sm),
            ...question.options.asMap().entries.map((entry) {
              final index = entry.key;
              final option = entry.value;
              final letter = String.fromCharCode(65 + index); // A, B, C, D...
              final isUserOption = option.id == answer.selectedOption;
              final isCorrectOption = option.isCorrect;

              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: _OptionResultTile(
                  letter: letter,
                  optionText: option.optionText,
                  isUserOption: isUserOption,
                  isCorrectOption: isCorrectOption,
                ),
              );
            }),
            if (question.explanation != null &&
                question.explanation!.trim().isNotEmpty)
              QuestionExplanationTile(
                explanation: question.explanation!,
                initiallyExpanded: !isCorrect,
              ),
          ],
          if (question == null)
            Text(
              answer.option.optionText,
              style: const TextStyle(fontSize: 15, height: 1.3),
            ),
        ],
      ),
    );
  }
}

class _OptionResultTile extends StatelessWidget {
  final String letter;
  final String optionText;
  final bool isUserOption;
  final bool isCorrectOption;

  const _OptionResultTile({
    required this.letter,
    required this.optionText,
    required this.isUserOption,
    required this.isCorrectOption,
  });

  @override
  Widget build(BuildContext context) {
    final Color borderColor;
    final Color bgColor;
    final IconData? trailingIcon;

    if (isUserOption && isCorrectOption) {
      // El usuario acertó - opción correcta y seleccionada
      borderColor = AppColors.success;
      bgColor = AppColors.successSoftBg;
      trailingIcon = Icons.check_circle;
    } else if (isUserOption && !isCorrectOption) {
      // El usuario falló - opción seleccionada pero incorrecta
      borderColor = AppColors.danger;
      bgColor = AppColors.dangerSoftBg;
      trailingIcon = Icons.cancel;
    } else if (!isUserOption && isCorrectOption) {
      // Opción correcta no seleccionada
      borderColor = AppColors.success;
      bgColor = AppColors.successSoftBg.withValues(alpha: 0.5);
      trailingIcon = Icons.check;
    } else {
      // Opción normal
      borderColor = AppColors.border;
      bgColor = AppColors.surface;
      trailingIcon = null;
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: borderColor, width: 1.5),
        color: bgColor,
      ),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isUserOption || isCorrectOption
                  ? borderColor
                  : AppColors.background,
            ),
            child: Text(
              letter,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isUserOption || isCorrectOption
                    ? Colors.white
                    : AppColors.textMuted,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              optionText,
              style: const TextStyle(
                fontSize: 14,
                height: 1.3,
                color: Colors.black87,
              ),
            ),
          ),
          if (trailingIcon != null)
            Icon(trailingIcon, size: 20, color: borderColor),
        ],
      ),
    );
  }
}
