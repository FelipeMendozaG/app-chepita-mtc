import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/question.dart';
import '../providers/simulation_provider.dart';
import '../services/question_service.dart';
import '../theme/app_theme.dart';
import '../widgets/buttons/primary_button.dart';
import '../widgets/buttons/secondary_button.dart';
import '../widgets/states/custom_empty_state.dart';
import '../widgets/states/custom_error_state.dart';
import '../widgets/states/custom_loading_state.dart';

/// Elapsed time (in minutes) after which the timer chip switches to a warning style.
const int _warningThresholdMinutes = 25;

class SimulationScreen extends ConsumerStatefulWidget {
  const SimulationScreen({super.key});

  @override
  ConsumerState<SimulationScreen> createState() => _SimulationScreenState();
}

class _SimulationScreenState extends ConsumerState<SimulationScreen> {
  Timer? _timer;
  int _elapsedSeconds = 0;

  @override
  void initState() {
    super.initState();
    _startTimer();
    Future.microtask(() {
      ref.read(simulationProvider.notifier).startSimulation();
    });
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _elapsedSeconds++;
        });
      }
    });
  }

  String get _formattedTime {
    final minutes = _elapsedSeconds ~/ 60;
    final seconds = _elapsedSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  bool get _isTimeWarning => _elapsedSeconds ~/ 60 >= _warningThresholdMinutes;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final simulationState = ref.watch(simulationProvider);
    final notifier = ref.read(simulationProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Simulacro'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.lg),
            child: Center(
              child: _TimerChip(time: _formattedTime, warning: _isTimeWarning),
            ),
          ),
        ],
      ),
      body: simulationState.when(
        loading: () => const CustomLoadingState(),
        error: (error, stackTrace) => CustomErrorState(
          message: 'Error: $error',
          onRetry: () {
            setState(() {
              _elapsedSeconds = 0;
            });
            notifier.startSimulation();
          },
        ),
        data: (questions) {
          if (questions.isEmpty) {
            return const CustomEmptyState(
              icon: Icons.quiz_outlined,
              title: 'No hay preguntas disponibles',
            );
          }

          final currentQuestion = questions[notifier.currentIndex];
          final selectedAnswer = notifier.selectedAnswerFor(currentQuestion.id);

          return Column(
            children: [
              // Barra de progreso
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.sm,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Pregunta ${notifier.currentIndex + 1} de ${notifier.totalQuestions}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${(notifier.progress * 100).toStringAsFixed(0)}%',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: notifier.progress,
                        minHeight: 8,
                        backgroundColor: AppColors.border,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Pregunta actual
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: _QuestionStep(
                    question: currentQuestion,
                    selectedAnswer: selectedAnswer,
                    onSelect: (optionId) {
                      notifier.selectAnswer(currentQuestion.id, optionId);
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: simulationState.maybeWhen(
        data: (questions) {
          if (questions.isEmpty) return null;
          final currentQuestion = questions[notifier.currentIndex];
          final selectedAnswer = notifier.selectedAnswerFor(currentQuestion.id);
          final isLast = notifier.currentIndex == notifier.totalQuestions - 1;

          return SafeArea(
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SecondaryButton(
                    label: 'Anterior',
                    icon: Icons.chevron_left,
                    onPressed: notifier.currentIndex > 0
                        ? () => notifier.previousQuestion()
                        : null,
                  ),
                  Flexible(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xs,
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          '${notifier.answeredCount} respondidas',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textMuted,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                  PrimaryButton(
                    label: isLast ? 'Finalizar' : 'Siguiente',
                    icon: Icons.chevron_right,
                    iconAlignment: IconAlignment.end,
                    onPressed: selectedAnswer == null
                        ? null
                        : () {
                            if (!isLast) {
                              notifier.nextQuestion();
                            } else {
                              _showFinishDialog(notifier);
                            }
                          },
                  ),
                ],
              ),
            ),
          );
        },
        orElse: () => null,
      ),
    );
  }

  void _showFinishDialog(SimulationNotifier notifier) {
    final pending = notifier.totalQuestions - notifier.answeredCount;
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        title: const Text('¿Finalizar simulacro?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _FinishStatRow(
              icon: Icons.check_circle,
              color: AppColors.success,
              label: 'Respondidas',
              value: '${notifier.answeredCount}',
            ),
            const SizedBox(height: AppSpacing.sm),
            _FinishStatRow(
              icon: Icons.radio_button_unchecked,
              color: AppColors.warning,
              label: 'Pendientes',
              value: '$pending',
            ),
            const SizedBox(height: AppSpacing.sm),
            _FinishStatRow(
              icon: Icons.timer,
              color: AppColors.primary,
              label: 'Tiempo transcurrido',
              value: _formattedTime,
            ),
            const SizedBox(height: AppSpacing.lg),
            const Text(
              'Se guardarán tus respuestas.',
              style: TextStyle(fontSize: 13, color: AppColors.textMuted),
            ),
          ],
        ),
        actions: [
          SecondaryButton(
            label: 'Cancelar',
            onPressed: () => Navigator.pop(dialogContext),
          ),
          PrimaryButton(
            label: 'Guardar',
            onPressed: () {
              Navigator.pop(dialogContext);
              _saveAnswers(notifier);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _saveAnswers(SimulationNotifier notifier) async {
    final attemptId = notifier.idAttempt;
    if (attemptId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error: No se encontró el intento del simulacro'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
      return;
    }

    try {
      final questionService = QuestionService();
      await questionService.saveAttemptAnswers(
        attemptId: attemptId,
        answers: notifier.selectedAnswers,
      );

      _timer?.cancel();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Respuestas guardadas correctamente'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar las respuestas: $error'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }
}

class _TimerChip extends StatelessWidget {
  final String time;
  final bool warning;

  const _TimerChip({required this.time, required this.warning});

  @override
  Widget build(BuildContext context) {
    final color = warning ? AppColors.warning : AppColors.primary;
    final bg = warning ? AppColors.warningSoftBg : AppColors.infoSoftBg;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.timer_outlined, size: 18, color: color),
          const SizedBox(width: 6),
          Text(
            time,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _FinishStatRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;

  const _FinishStatRow({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: Text(label, style: const TextStyle(fontSize: 14))),
        Text(
          value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

class _QuestionStep extends StatelessWidget {
  final Question question;
  final int? selectedAnswer;
  final ValueChanged<int> onSelect;

  const _QuestionStep({
    required this.question,
    required this.selectedAnswer,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.infoSoftBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Pregunta ${question.number}',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.successSoftBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                question.licenseCategory,
                style: const TextStyle(
                  color: AppColors.success,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          question.question,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            height: 1.4,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          question.topic,
          style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
        ),
        if (question.imageUrl != null && question.imageUrl!.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.border),
            ),
            clipBehavior: Clip.antiAlias,
            child: Image.network(
              question.imageUrl!,
              width: double.infinity,
              height: 200,
              fit: BoxFit.contain,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  height: 200,
                  alignment: Alignment.center,
                  color: AppColors.background,
                  child: const CircularProgressIndicator(),
                );
              },
              errorBuilder: (context, error, stackTrace) => Container(
                height: 200,
                alignment: Alignment.center,
                color: AppColors.background,
                child: const Icon(
                  Icons.broken_image_outlined,
                  size: 48,
                  color: AppColors.textMuted,
                ),
              ),
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.xl),
        ...question.options.asMap().entries.map((entry) {
          final index = entry.key;
          final option = entry.value;
          final letter = String.fromCharCode(65 + index); // A, B, C, D...
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: _OptionTile(
              option: option,
              letter: letter,
              isSelected: selectedAnswer == option.id,
              onTap: () => onSelect(option.id),
            ),
          );
        }),
      ],
    );
  }
}

class _OptionTile extends StatelessWidget {
  final QuestionOption option;
  final String letter;
  final bool isSelected;
  final VoidCallback onTap;

  const _OptionTile({
    required this.option,
    required this.letter,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.border,
              width: isSelected ? 2 : 1,
            ),
            color: isSelected ? AppColors.infoSoftBg : AppColors.surface,
          ),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? AppColors.primary : AppColors.background,
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.border,
                  ),
                ),
                child: Text(
                  letter,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : AppColors.textMuted,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  option.optionText,
                  style: const TextStyle(fontSize: 15, height: 1.3),
                ),
              ),
              if (isSelected)
                const Icon(
                  Icons.check_circle,
                  color: AppColors.primary,
                  size: 22,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
