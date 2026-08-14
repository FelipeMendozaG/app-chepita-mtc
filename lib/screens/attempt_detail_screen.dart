import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/attempt.dart';
import '../providers/attempt_provider.dart';

class AttemptDetailScreen extends ConsumerWidget {
  final int attemptId;

  const AttemptDetailScreen({super.key, required this.attemptId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(attemptDetailProvider(attemptId));

    return Scaffold(
      appBar: AppBar(title: const Text('Detalle del Intento')),
      body: detailAsync.when(
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
                    ref.invalidate(attemptDetailProvider(attemptId));
                  },
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          ),
        ),
        data: (attempt) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SummaryCard(attempt: attempt),
                const SizedBox(height: 24),
                const Text(
                  'Detalle de respuestas',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                if (attempt.answers.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'No hay respuestas registradas para este intento',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                else
                  ...attempt.answers.asMap().entries.map((entry) {
                    final index = entry.key;
                    final answer = entry.value;
                    return _QuestionDetailCard(
                      number: index + 1,
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

  String _formatDate(DateTime? date) {
    if (date == null) return '—';
    final local = date.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final year = local.year;
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $hour:$minute';
  }

  String _formatDuration() {
    if (attempt.startedAt == null || attempt.finishedAt == null) {
      return '—';
    }
    final duration = attempt.finishedAt!.difference(attempt.startedAt!);
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')} min';
  }

  @override
  Widget build(BuildContext context) {
    final approved = attempt.approved;
    final score = attempt.score;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
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
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: approved
                        ? Colors.green.withValues(alpha: 0.1)
                        : Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    approved ? 'APROBADO' : 'DESAPROBADO',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: approved ? Colors.green : Colors.red,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                const SizedBox(width: 6),
                Text(
                  'Inicio: ${_formatDate(attempt.startedAt)}',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.flag, size: 16, color: Colors.grey),
                const SizedBox(width: 6),
                Text(
                  'Fin: ${_formatDate(attempt.finishedAt)}',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.timer, size: 16, color: Colors.grey),
                const SizedBox(width: 6),
                Text(
                  'Duración: ${_formatDuration()}',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _DetailStat(
                  icon: Icons.quiz,
                  label: 'Preguntas',
                  value: '${attempt.totalQuestions}',
                  color: Colors.blue,
                ),
                _DetailStat(
                  icon: Icons.check_circle,
                  label: 'Correctas',
                  value: '${attempt.correctAnswers}',
                  color: Colors.green,
                ),
                _DetailStat(
                  icon: Icons.cancel,
                  label: 'Incorrectas',
                  value: '${attempt.wrongAnswers}',
                  color: Colors.red,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
              ),
              child: Column(
                children: [
                  const Text(
                    'PUNTAJE FINAL',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    score.toStringAsFixed(2),
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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
    return Column(
      children: [
        Icon(icon, size: 28, color: color),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
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

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
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
                        ? Colors.green.withValues(alpha: 0.1)
                        : Colors.red.withValues(alpha: 0.1),
                  ),
                  child: Icon(
                    isCorrect ? Icons.check : Icons.close,
                    size: 18,
                    color: isCorrect ? Colors.green : Colors.red,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Pregunta $number',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  isCorrect ? 'Correcta' : 'Incorrecta',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isCorrect ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (question != null) ...[
              Text(
                question.question,
                style: const TextStyle(fontSize: 15, height: 1.4),
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 12),
              const Text(
                'Opciones:',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...question.options.asMap().entries.map((entry) {
                final index = entry.key;
                final option = entry.value;
                final letter = String.fromCharCode(65 + index); // A, B, C, D...
                final isUserOption = option.id == answer.selectedOption;
                final isCorrectOption = option.isCorrect;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _OptionResultTile(
                    letter: letter,
                    optionText: option.optionText,
                    isUserOption: isUserOption,
                    isCorrectOption: isCorrectOption,
                  ),
                );
              }),
            ],
            if (question == null)
              Text(
                answer.option.optionText,
                style: const TextStyle(fontSize: 15, height: 1.3),
              ),
          ],
        ),
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
    final Color textColor;
    final IconData? trailingIcon;

    if (isUserOption && isCorrectOption) {
      // El usuario acertó - opción correcta y seleccionada
      borderColor = Colors.green;
      bgColor = Colors.green.withValues(alpha: 0.08);
      textColor = Colors.black87;
      trailingIcon = Icons.check_circle;
    } else if (isUserOption && !isCorrectOption) {
      // El usuario falló - opción seleccionada pero incorrecta
      borderColor = Colors.red;
      bgColor = Colors.red.withValues(alpha: 0.08);
      textColor = Colors.black87;
      trailingIcon = Icons.cancel;
    } else if (!isUserOption && isCorrectOption) {
      // Opción correcta no seleccionada
      borderColor = Colors.green;
      bgColor = Colors.green.withValues(alpha: 0.05);
      textColor = Colors.black87;
      trailingIcon = Icons.check;
    } else {
      // Opción normal
      borderColor = Colors.grey.shade300;
      bgColor = Colors.white;
      textColor = Colors.black87;
      trailingIcon = null;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
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
                  : Colors.grey.shade200,
            ),
            child: Text(
              letter,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isUserOption || isCorrectOption
                    ? Colors.white
                    : Colors.grey.shade700,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              optionText,
              style: TextStyle(fontSize: 14, height: 1.3, color: textColor),
            ),
          ),
          if (trailingIcon != null)
            Icon(trailingIcon, size: 20, color: borderColor),
        ],
      ),
    );
  }
}
