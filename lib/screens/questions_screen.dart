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

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedTopic = 'Todos';

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(questionProvider.notifier).loadQuestions();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _clearFilters() {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
      _selectedTopic = 'Todos';
    });
  }

  @override
  Widget build(BuildContext context) {
    final questionsState = ref.watch(questionProvider);
    final notifier = ref.read(questionProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ver Preguntas'),
        actions: [
          if (_searchQuery.isNotEmpty || _selectedTopic != 'Todos')
            IconButton(
              icon: const Icon(Icons.filter_alt_off_rounded),
              tooltip: 'Limpiar filtros',
              onPressed: _clearFilters,
            ),
        ],
      ),
      body: Column(
        children: [
          // Barra de controles de paginación y límite
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.sm,
            ),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                const Text(
                  'Mostrar:',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: AppSpacing.sm),
                DropdownButton<int>(
                  value: notifier.limit,
                  underline: const SizedBox.shrink(),
                  isDense: true,
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

          // Barra de búsqueda en tiempo real
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.sm,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.border),
                boxShadow: AppShadows.soft,
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val.trim().toLowerCase();
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Buscar por pregunta, tema o materia...',
                  hintStyle: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textMuted,
                  ),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: AppColors.primary,
                    size: 22,
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close_rounded, size: 20),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                            });
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                ),
              ),
            ),
          ),

          // Contenido principal (Chips de categorías + Lista filtrada)
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

                // Extracción dinámica de temas de la página actual
                final availableTopics = <String>{};
                for (final q in questions) {
                  if (q.topic.trim().isNotEmpty) {
                    availableTopics.add(q.topic.trim());
                  }
                }
                final topicsList = ['Todos', ...availableTopics];

                // Filtrado reactivo en tiempo real
                final filteredQuestions = questions.where((q) {
                  final matchesTopic = _selectedTopic == 'Todos' ||
                      q.topic.trim() == _selectedTopic ||
                      q.subject.trim() == _selectedTopic;
                  if (!matchesTopic) return false;

                  if (_searchQuery.isEmpty) return true;
                  final inQ = q.question.toLowerCase().contains(_searchQuery);
                  final inTopic = q.topic.toLowerCase().contains(_searchQuery);
                  final inSubject =
                      q.subject.toLowerCase().contains(_searchQuery);
                  final inOptions = q.options.any(
                    (opt) =>
                        opt.optionText.toLowerCase().contains(_searchQuery),
                  );
                  return inQ || inTopic || inSubject || inOptions;
                }).toList();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Carrusel horizontal de Chips de Temas / Categorías
                    if (topicsList.length > 2)
                      Container(
                        height: 38,
                        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: ListView.separated(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg,
                          ),
                          scrollDirection: Axis.horizontal,
                          itemCount: topicsList.length,
                          separatorBuilder: (_, _) => const SizedBox(width: 8),
                          itemBuilder: (context, index) {
                            final topic = topicsList[index];
                            final isSelected = _selectedTopic == topic;

                            return InkWell(
                              onTap: () {
                                setState(() {
                                  _selectedTopic = topic;
                                });
                              },
                              borderRadius: BorderRadius.circular(
                                AppRadius.full,
                              ),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.primary
                                      : AppColors.surface,
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.full,
                                  ),
                                  border: Border.all(
                                    color: isSelected
                                        ? AppColors.primary
                                        : AppColors.border,
                                    width: isSelected ? 1.5 : 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      topic == 'Todos'
                                          ? Icons.all_inclusive_rounded
                                          : Icons.category_rounded,
                                      size: 14,
                                      color: isSelected
                                          ? Colors.white
                                          : AppColors.textMuted,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      topic,
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: isSelected
                                            ? FontWeight.bold
                                            : FontWeight.w500,
                                        color: isSelected
                                            ? Colors.white
                                            : AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                    // Barra indicadora de resultados filtrados
                    if (_searchQuery.isNotEmpty || _selectedTopic != 'Todos')
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                          vertical: 4,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${filteredQuestions.length} de ${questions.length} preguntas encontradas',
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                            InkWell(
                              onTap: _clearFilters,
                              child: const Text(
                                'Restablecer',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Lista de preguntas o estado vacío
                    Expanded(
                      child: filteredQuestions.isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(AppSpacing.xl),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.search_off_rounded,
                                      size: 54,
                                      color: AppColors.textMuted,
                                    ),
                                    const SizedBox(height: AppSpacing.md),
                                    const Text(
                                      'Sin resultados encontrados',
                                      style: TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    const Text(
                                      'No hay preguntas que coincidan con tus criterios de búsqueda o filtro.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                    const SizedBox(height: AppSpacing.lg),
                                    SecondaryButton(
                                      label: 'Limpiar búsqueda',
                                      icon: Icons.refresh_rounded,
                                      onPressed: _clearFilters,
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.all(AppSpacing.lg),
                              itemCount: filteredQuestions.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(height: AppSpacing.md),
                              itemBuilder: (context, index) {
                                final question = filteredQuestions[index];
                                return _QuestionCard(question: question);
                              },
                            ),
                    ),
                  ],
                );
              },
            ),
          ),

          // Paginador inferior
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
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
                    fontSize: 15,
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
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.surfaceSubtle,
                  borderRadius: BorderRadius.circular(AppRadius.xs),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  question.subject,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
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
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(
                Icons.bookmark_outline_rounded,
                size: 14,
                color: AppColors.textMuted,
              ),
              const SizedBox(width: 4),
              Text(
                question.topic,
                style: const TextStyle(
                  fontSize: 12.5,
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          if (question.imageUrl != null &&
              question.imageUrl!.trim().isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            QuestionImageWidget(imageUrl: question.imageUrl!),
          ],
          const SizedBox(height: AppSpacing.md),
          const Divider(height: 1),
          const SizedBox(height: AppSpacing.md),
          ...question.options.asMap().entries.map((entry) {
            final index = entry.key;
            final option = entry.value;
            final letter = String.fromCharCode(65 + index); // A, B, C, D...

            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: option.isCorrect
                      ? AppColors.successSoftBg
                      : AppColors.surfaceSubtle,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(
                    color: option.isCorrect
                        ? AppColors.success.withValues(alpha: 0.5)
                        : AppColors.border,
                    width: option.isCorrect ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 26,
                      height: 26,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: option.isCorrect
                            ? AppColors.success.withValues(alpha: 0.25)
                            : AppColors.border.withValues(alpha: 0.6),
                      ),
                      child: Text(
                        letter,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: option.isCorrect
                              ? AppColors.success
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          option.optionText,
                          style: TextStyle(
                            fontSize: 14.5,
                            height: 1.35,
                            color: option.isCorrect
                                ? const Color(0xFF1E6B3A)
                                : AppColors.textPrimary,
                            fontWeight: option.isCorrect
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                    if (option.isCorrect) ...[
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.check_circle_rounded,
                        color: AppColors.success,
                        size: 20,
                      ),
                    ],
                  ],
                ),
              ),
            );
          }),
          if (question.explanation != null &&
              question.explanation!.trim().isNotEmpty)
            QuestionExplanationTile(explanation: question.explanation!),
        ],
      ),
    );
  }
}
