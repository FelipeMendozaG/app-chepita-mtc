import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/question.dart';
import '../providers/simulation_provider.dart';
import '../services/question_service.dart';

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
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Row(
                children: [
                  const Icon(Icons.timer, size: 20),
                  const SizedBox(width: 4),
                  Text(
                    _formattedTime,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: simulationState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Error: $error',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _elapsedSeconds = 0;
                    });
                    notifier.startSimulation();
                  },
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          ),
        ),
        data: (questions) {
          if (questions.isEmpty) {
            return const Center(
              child: Text(
                'No hay preguntas disponibles',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          final currentQuestion = questions[notifier.currentIndex];
          final selectedAnswer = notifier.selectedAnswerFor(currentQuestion.id);

          return Column(
            children: [
              // Barra de progreso
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
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
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: notifier.progress,
                        minHeight: 8,
                        backgroundColor: Colors.grey.shade200,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Pregunta actual
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: _QuestionStep(
                    question: currentQuestion,
                    selectedAnswer: selectedAnswer,
                    onSelect: (optionId) {
                      notifier.selectAnswer(currentQuestion.id, optionId);
                    },
                  ),
                ),
              ),
              const Divider(height: 1),
              // Navegación
              Padding(
                padding: const EdgeInsets.all(
                  12,
                ), // Reducimos un poco el padding externo
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Botón Anterior
                    OutlinedButton.icon(
                      onPressed: notifier.currentIndex > 0
                          ? () => notifier.previousQuestion()
                          : null,
                      icon: const Icon(Icons.chevron_left),
                      label: const Text('Anterior'),
                    ),

                    // Texto de respondidas envuelto en Flexible/FittedBox para evitar desbordamientos
                    Flexible(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            '${notifier.answeredCount}',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.grey,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                    FilledButton.icon(
                      onPressed: selectedAnswer == null
                          ? null
                          : () {
                              if (notifier.currentIndex <
                                  notifier.totalQuestions - 1) {
                                notifier.nextQuestion();
                              } else {
                                _showFinishDialog(notifier);
                              }
                            },
                      icon: const Icon(Icons.chevron_right),
                      label: Text(
                        notifier.currentIndex == notifier.totalQuestions - 1
                            ? 'Finalizar'
                            : 'Siguiente',
                      ),
                      iconAlignment: IconAlignment.end,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showFinishDialog(SimulationNotifier notifier) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('¿Finalizar simulacro?'),
        content: Text(
          'Has respondido ${notifier.answeredCount} de ${notifier.totalQuestions} preguntas.\n\n'
          'Tiempo transcurrido: $_formattedTime\n\n'
          'Se guardarán tus respuestas.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _saveAnswers(notifier);
            },
            child: const Text('Guardar'),
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
            backgroundColor: Colors.red,
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
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar las respuestas: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Pregunta ${question.number}',
                style: const TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                question.licenseCategory,
                style: const TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          question.question,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          question.topic,
          style: const TextStyle(fontSize: 13, color: Colors.grey),
        ),
        if (question.imageUrl != null && question.imageUrl!.isNotEmpty) ...[
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              question.imageUrl!,
              width: double.infinity,
              // fit: BoxFit.cover,
              height: 200, // 👈 Ajusta la altura que prefieras en píxeles
              fit: BoxFit.contain,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  height: 100,
                  alignment: Alignment.center,
                  color: Colors.grey.shade100,
                  child: const CircularProgressIndicator(),
                );
              },
              errorBuilder: (context, error, stackTrace) => Container(
                height: 100,
                alignment: Alignment.center,
                color: Colors.grey.shade100,
                child: const Icon(
                  Icons.broken_image_outlined,
                  size: 48,
                  color: Colors.grey,
                ),
              ),
            ),
          ),
        ],
        const SizedBox(height: 24),
        ...question.options.asMap().entries.map((entry) {
          final index = entry.key;
          final option = entry.value;
          final letter = String.fromCharCode(65 + index); // A, B, C, D...
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          color: isSelected
              ? Colors.blue.withValues(alpha: 0.08)
              : Colors.white,
        ),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? Colors.blue : Colors.grey.shade100,
                border: Border.all(
                  color: isSelected ? Colors.blue : Colors.grey.shade400,
                ),
              ),
              child: Text(
                letter,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : Colors.grey.shade700,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                option.optionText,
                style: const TextStyle(fontSize: 15, height: 1.3),
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: Colors.blue, size: 22),
          ],
        ),
      ),
    );
  }
}
