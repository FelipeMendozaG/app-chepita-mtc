import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/question.dart';
import '../providers/question_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/buttons/secondary_button.dart';
import '../widgets/cards/app_card.dart';
import '../widgets/cards/question_explanation_tile.dart';
import '../widgets/cards/question_image_widget.dart';
import '../widgets/cards/status_badge.dart';
import '../widgets/states/custom_empty_state.dart';
import '../widgets/states/custom_error_state.dart';
import '../widgets/states/custom_loading_state.dart';

class QuestionsScreen extends ConsumerStatefulWidget {
  const QuestionsScreen({super.key});

  @override
  ConsumerState<QuestionsScreen> createState() => _QuestionsScreenState();
}

class _QuestionsScreenState extends ConsumerState<QuestionsScreen> {
  static const List<int> _limitOptions = [5, 10, 15, 20, 30];

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(questionProvider.notifier).loadQuestions();
    });
  }

  @override
  Widget build(BuildContext context) {
    final questionsState = ref.watch(questionProvider);
    final notifier = ref.read(questionProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Ver Preguntas')),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                const Text(
                  'Mostrar:',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: AppSpacing.md),
                DropdownButton<int>(
                  value: notifier.limit,
                  underline: const SizedBox.shrink(),
                  items: _limitOptions
                      .map(
                        (limit) => DropdownMenuItem(
                          value: limit,
                          child: Text('$limit preguntas'),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      notifier.changeLimit(value);
                    }
                  },
                ),
                const Spacer(),
                StatusBadge(
                  label: 'Pág. ${notifier.currentPage}/${notifier.totalPages}',
                  type: StatusBadgeType.info,
                ),
              ],
            ),
          ),
          Expanded(
            child: questionsState.when(
              loading: () => const CustomLoadingState(),
              error: (error, stackTrace) => CustomErrorState(
                message: 'Error: $error',
                onRetry: () => notifier.loadQuestions(),
              ),
              data: (questions) {
                if (questions.isEmpty) {
                  return const CustomEmptyState(
                    icon: Icons.quiz_outlined,
                    title: 'No hay preguntas disponibles',
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  itemCount: questions.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppSpacing.md),
                  itemBuilder: (context, index) {
                    final question = questions[index];
                    return _QuestionCard(question: question);
                  },
                );
              },
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SecondaryButton(
                  label: 'Anterior',
                  icon: Icons.chevron_left,
                  onPressed: notifier.currentPage > 1
                      ? () => notifier.previousPage()
                      : null,
                ),
                Text(
                  '${notifier.currentPage} / ${notifier.totalPages}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SecondaryButton(
                  label: 'Siguiente',
                  icon: Icons.chevron_right,
                  iconAlignment: IconAlignment.end,
                  onPressed: notifier.currentPage < notifier.totalPages
                      ? () => notifier.nextPage()
                      : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuestionCard extends StatelessWidget {
  final Question question;

  const _QuestionCard({required this.question});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              StatusBadge(
                label: 'Pregunta ${question.number}',
                type: StatusBadgeType.info,
              ),
              const SizedBox(width: AppSpacing.sm),
              StatusBadge(
                label: question.licenseCategory,
                type: StatusBadgeType.success,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            question.question,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            question.topic,
            style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            question.subject,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (question.imageUrl != null &&
              question.imageUrl!.trim().isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            QuestionImageWidget(imageUrl: question.imageUrl!),
          ],
          const SizedBox(height: AppSpacing.md),
          const Divider(height: 1),
          const SizedBox(height: AppSpacing.md),
          ...question.options.map(
            (option) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: option.isCorrect
                      ? AppColors.successSoftBg
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  border: option.isCorrect
                      ? Border.all(
                          color: AppColors.success.withValues(alpha: 0.4),
                        )
                      : null,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: option.isCorrect
                            ? AppColors.success.withValues(alpha: 0.2)
                            : AppColors.border.withValues(alpha: 0.6),
                      ),
                      child: Text(
                        option.optionNumber.toString(),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: option.isCorrect
                              ? AppColors.success
                              : AppColors.textMuted,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        option.optionText,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.3,
                          color: option.isCorrect
                              ? const Color(0xFF1E6B3A)
                              : Colors.black87,
                          fontWeight: option.isCorrect
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                    if (option.isCorrect)
                      const Icon(
                        Icons.check_circle,
                        color: AppColors.success,
                        size: 20,
                      ),
                  ],
                ),
              ),
            ),
          ),
          if (question.explanation != null &&
              question.explanation!.trim().isNotEmpty)
            QuestionExplanationTile(explanation: question.explanation!),
        ],
      ),
    );
  }
}
