import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/question.dart';
import '../providers/simulation_provider.dart';
import '../services/question_service.dart';
import '../theme/app_theme.dart';
import '../widgets/buttons/primary_button.dart';
import '../widgets/buttons/secondary_button.dart';
import '../widgets/cards/question_image_widget.dart';
import '../widgets/states/custom_empty_state.dart';
import '../widgets/states/custom_error_state.dart';
import '../widgets/states/custom_loading_state.dart';

/// Official MTC simulation time is 40 minutes (countdown).
const int _examDurationMinutes = 40;
const int _totalExamSeconds = _examDurationMinutes * 60;
const int _warningThresholdSeconds = 10 * 60; // 10 minutes remaining
const int _criticalThresholdSeconds = 5 * 60; // 5 minutes remaining

enum TimerSeverity { normal, warning, critical }

class SimulationScreen extends ConsumerStatefulWidget {
  const SimulationScreen({super.key});

  @override
  ConsumerState<SimulationScreen> createState() => _SimulationScreenState();
}

class _SimulationScreenState extends ConsumerState<SimulationScreen> {
  Timer? _timer;
  int _remainingSeconds = _totalExamSeconds;
  bool _isSaving = false;

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
      if (!mounted) return;
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
        if (_remainingSeconds == 0) {
          timer.cancel();
          _onTimeExpired();
        }
      }
    });
  }

  String get _formattedTime {
    final minutes = _remainingSeconds ~/ 60;
    final seconds = _remainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  int get _elapsedSeconds => _totalExamSeconds - _remainingSeconds;

  String get _formattedElapsedTime {
    final minutes = _elapsedSeconds ~/ 60;
    final seconds = _elapsedSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  TimerSeverity get _timerSeverity {
    if (_remainingSeconds <= _criticalThresholdSeconds) {
      return TimerSeverity.critical;
    } else if (_remainingSeconds <= _warningThresholdSeconds) {
      return TimerSeverity.warning;
    }
    return TimerSeverity.normal;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _onTimeExpired() {
    if (!mounted) return;
    final notifier = ref.read(simulationProvider.notifier);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        icon: const Icon(
          Icons.alarm_off_rounded,
          color: AppColors.danger,
          size: 48,
        ),
        title: const Text('¡Tiempo agotado!'),
        content: const Text(
          'Se cumplió el tiempo límite de 40 minutos para el examen oficial del MTC. Tus respuestas serán guardadas.',
          textAlign: TextAlign.center,
        ),
        actions: [
          PrimaryButton(
            label: 'Guardar y Finalizar',
            onPressed: () {
              Navigator.pop(dialogContext);
              _saveAnswers(notifier);
            },
          ),
        ],
      ),
    );
  }

  void _showQuestionsNavigator(
    BuildContext context,
    SimulationNotifier notifier,
    List<Question> questions,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (sheetContext) {
        return Consumer(
          builder: (context, ref, _) {
            final currentSimState = ref.watch(simulationProvider);
            final currentNotifier = ref.read(simulationProvider.notifier);
            final currentQuestions = currentSimState.value ?? questions;

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.lg,
                  AppSpacing.lg,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Navegación de Preguntas',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(sheetContext),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _legendItem(
                          color: AppColors.successSoftBg,
                          borderColor: AppColors.success,
                          textColor: AppColors.success,
                          label:
                              'Respondidas (${currentNotifier.answeredCount})',
                        ),
                        _legendItem(
                          color: AppColors.background,
                          borderColor: AppColors.border,
                          textColor: AppColors.textMuted,
                          label:
                              'Pendientes (${currentNotifier.totalQuestions - currentNotifier.answeredCount})',
                        ),
                        _legendItem(
                          color: AppColors.infoSoftBg,
                          borderColor: AppColors.primary,
                          textColor: AppColors.primary,
                          label: 'Actual',
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    const Divider(height: 1),
                    const SizedBox(height: AppSpacing.md),
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.45,
                      ),
                      child: GridView.builder(
                        shrinkWrap: true,
                        itemCount: currentQuestions.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 6,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                              childAspectRatio: 1,
                            ),
                        itemBuilder: (gridContext, index) {
                          final question = currentQuestions[index];
                          final isAnswered =
                              currentNotifier.selectedAnswerFor(question.id) !=
                              null;
                          final isCurrent =
                              currentNotifier.currentIndex == index;

                          final Color bgColor;
                          final Color borderColor;
                          final Color textColor;

                          if (isCurrent) {
                            bgColor = AppColors.infoSoftBg;
                            borderColor = AppColors.primary;
                            textColor = AppColors.primary;
                          } else if (isAnswered) {
                            bgColor = AppColors.successSoftBg;
                            borderColor = AppColors.success.withValues(
                              alpha: 0.6,
                            );
                            textColor = AppColors.success;
                          } else {
                            bgColor = AppColors.background;
                            borderColor = AppColors.border;
                            textColor = AppColors.textMuted;
                          }

                          return InkWell(
                            onTap: () {
                              currentNotifier.goToQuestion(index);
                              Navigator.pop(sheetContext);
                            },
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            child: Container(
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: bgColor,
                                borderRadius: BorderRadius.circular(
                                  AppRadius.md,
                                ),
                                border: Border.all(
                                  color: borderColor,
                                  width: isCurrent ? 2 : 1,
                                ),
                              ),
                              child: Text(
                                '${index + 1}',
                                style: TextStyle(
                                  fontWeight: isCurrent || isAnswered
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                                  fontSize: 14,
                                  color: textColor,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    SizedBox(
                      width: double.infinity,
                      child: PrimaryButton(
                        label: 'Finalizar Simulacro',
                        icon: Icons.check_circle_outline,
                        onPressed: () {
                          Navigator.pop(sheetContext);
                          _showFinishDialog(currentNotifier);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _legendItem({
    required Color color,
    required Color borderColor,
    required Color textColor,
    required String label,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
            border: Border.all(color: borderColor),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
      ],
    );
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
            padding: const EdgeInsets.only(right: AppSpacing.xs),
            child: Center(
              child: _TimerChip(time: _formattedTime, severity: _timerSeverity),
            ),
          ),
          if (simulationState.hasValue &&
              (simulationState.value?.isNotEmpty ?? false))
            IconButton(
              icon: const Icon(Icons.grid_view_rounded),
              tooltip: 'Ver todas las preguntas',
              onPressed: () => _showQuestionsNavigator(
                context,
                notifier,
                simulationState.value!,
              ),
            ),
          const SizedBox(width: AppSpacing.xs),
        ],
      ),
      body: simulationState.when(
        loading: () => const CustomLoadingState(),
        error: (error, stackTrace) => CustomErrorState(
          message: 'Error: $error',
          onRetry: () {
            setState(() {
              _remainingSeconds = _totalExamSeconds;
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
              // Barra de progreso interactiva
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
                        InkWell(
                          onTap: () => _showQuestionsNavigator(
                            context,
                            notifier,
                            questions,
                          ),
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 4,
                              horizontal: 2,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Pregunta ${notifier.currentIndex + 1} de ${notifier.totalQuestions}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Icon(
                                  Icons.grid_view_rounded,
                                  size: 16,
                                  color: AppColors.primary,
                                ),
                              ],
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.infoSoftBg,
                            borderRadius: BorderRadius.circular(AppRadius.full),
                            border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.2),
                              width: 0.8,
                            ),
                          ),
                          child: Text(
                            '${(notifier.progress * 100).toStringAsFixed(0)}%',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TweenAnimationBuilder<double>(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutCubic,
                      tween: Tween<double>(begin: 0, end: notifier.progress),
                      builder: (context, progressVal, _) => ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadius.full),
                        child: LinearProgressIndicator(
                          value: progressVal,
                          minHeight: 8,
                          backgroundColor: AppColors.borderSubtle,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            AppColors.primary,
                          ),
                        ),
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
          final isAnswered = notifier.selectedAnswerFor(currentQuestion.id) != null;
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
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${notifier.answeredCount}/${notifier.totalQuestions} respondidas',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textMuted,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              isAnswered ? 'Respondida' : 'Sin responder',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isAnswered
                                    ? AppColors.success
                                    : AppColors.warning,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  PrimaryButton(
                    label: isLast ? 'Finalizar' : 'Siguiente',
                    icon: isLast
                        ? Icons.check_circle_outline
                        : Icons.chevron_right,
                    iconAlignment: IconAlignment.end,
                    onPressed: () {
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
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
        titlePadding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.xl,
          AppSpacing.xl,
          AppSpacing.sm,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.sm,
        ),
        actionsPadding: const EdgeInsets.all(AppSpacing.lg),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: pending > 0
                    ? AppColors.warningSoftBg
                    : AppColors.infoSoftBg,
                shape: BoxShape.circle,
              ),
              child: Icon(
                pending > 0
                    ? Icons.help_outline_rounded
                    : Icons.check_circle_rounded,
                color: pending > 0 ? AppColors.warning : AppColors.primary,
                size: 26,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            const Expanded(
              child: Text(
                '¿Finalizar simulacro?',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (pending > 0)
              Container(
                margin: const EdgeInsets.only(bottom: AppSpacing.md),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppColors.warningSoftBg,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(
                    color: AppColors.warning.withValues(alpha: 0.35),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: AppColors.warning,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Tienes $pending ${pending == 1 ? "pregunta sin responder" : "preguntas sin responder"}. Las no respondidas sumarán 0 puntos.',
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF92400E),
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              Container(
                margin: const EdgeInsets.only(bottom: AppSpacing.md),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppColors.successSoftBg,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(
                    color: AppColors.success.withValues(alpha: 0.35),
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.check_circle_outline_rounded,
                      color: AppColors.success,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '¡Excelente! Has respondido todas las preguntas del examen.',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF166534),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.surfaceSubtle,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  _FinishStatRow(
                    icon: Icons.check_circle_rounded,
                    color: AppColors.success,
                    label: 'Respondidas',
                    value:
                        '${notifier.answeredCount} de ${notifier.totalQuestions}',
                  ),
                  const Divider(height: 16),
                  _FinishStatRow(
                    icon: Icons.radio_button_unchecked,
                    color: AppColors.warning,
                    label: 'Pendientes',
                    value: '$pending',
                  ),
                  const Divider(height: 16),
                  _FinishStatRow(
                    icon: Icons.timer_outlined,
                    color: AppColors.primary,
                    label: 'Tiempo transcurrido',
                    value: _formattedElapsedTime,
                  ),
                  const Divider(height: 16),
                  _FinishStatRow(
                    icon: Icons.hourglass_bottom_rounded,
                    color: AppColors.warning,
                    label: 'Tiempo restante',
                    value: _formattedTime,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            const Text(
              'Se guardarán tus respuestas y finalizará el examen.',
              style: TextStyle(fontSize: 12.5, color: AppColors.textMuted),
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
    if (_isSaving) return;
    _isSaving = true;

    final attemptId = notifier.idAttempt;
    if (attemptId == null) {
      _isSaving = false;
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
      _isSaving = false;
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
  final TimerSeverity severity;

  const _TimerChip({required this.time, required this.severity});

  @override
  Widget build(BuildContext context) {
    final Color color;
    final Color bg;
    final IconData icon;

    switch (severity) {
      case TimerSeverity.critical:
        color = AppColors.danger;
        bg = AppColors.dangerSoftBg;
        icon = Icons.alarm_rounded;
        break;
      case TimerSeverity.warning:
        color = AppColors.warning;
        bg = AppColors.warningSoftBg;
        icon = Icons.timer_outlined;
        break;
      case TimerSeverity.normal:
        color = AppColors.primary;
        bg = AppColors.infoSoftBg;
        icon = Icons.timer_outlined;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: severity == TimerSeverity.critical
            ? Border.all(
                color: AppColors.danger.withValues(alpha: 0.6),
                width: 1.5,
              )
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            time,
            style: TextStyle(
              fontSize: 14,
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
        if (question.imageUrl != null &&
            question.imageUrl!.trim().isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          QuestionImageWidget(imageUrl: question.imageUrl!),
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
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: 14,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.border,
              width: isSelected ? 2 : 1,
            ),
            color: isSelected
                ? AppColors.infoSoftBg.withValues(alpha: 0.7)
                : AppColors.surface,
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : AppShadows.soft,
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.surfaceSubtle,
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.border,
                    width: 1.2,
                  ),
                ),
                child: Text(
                  letter,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  option.optionText,
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.35,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: isSelected
                    ? const Icon(
                        Icons.check_circle_rounded,
                        key: ValueKey('selected'),
                        color: AppColors.primary,
                        size: 22,
                      )
                    : Icon(
                        Icons.radio_button_unchecked,
                        key: const ValueKey('unselected'),
                        color: AppColors.border.withValues(alpha: 0.9),
                        size: 22,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
