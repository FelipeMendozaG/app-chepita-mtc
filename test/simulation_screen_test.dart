import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app_chepita_mtc/models/question.dart';
import 'package:app_chepita_mtc/models/simulacrum_data.dart';
import 'package:app_chepita_mtc/providers/question_provider.dart';
import 'package:app_chepita_mtc/screens/simulation_screen.dart';
import 'package:app_chepita_mtc/services/question_service.dart';

void main() {
  testWidgets('SimulationScreen allows skipping questions without answering', (
    WidgetTester tester,
  ) async {
    final questions = [
      const Question(
        id: 1,
        number: 1,
        subject: 'Reglas',
        topic: 'Prioridad',
        licenseCategory: 'A-I',
        question: '¿Quién tiene prioridad en una rotonda?',
        options: [
          QuestionOption(
            id: 101,
            optionNumber: 1,
            optionText: 'El que entra',
            isCorrect: false,
          ),
          QuestionOption(
            id: 102,
            optionNumber: 2,
            optionText: 'El que ya circula',
            isCorrect: true,
          ),
        ],
      ),
      const Question(
        id: 2,
        number: 2,
        subject: 'Reglas',
        topic: 'Velocidades',
        licenseCategory: 'A-I',
        question: '¿Cuál es la velocidad máxima en zona escolar?',
        options: [
          QuestionOption(
            id: 201,
            optionNumber: 1,
            optionText: '30 km/h',
            isCorrect: true,
          ),
        ],
      ),
    ];

    final fakeService = FakeQuestionService(
      SimulacrumData(idAttempt: 99, questions: questions),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [questionServiceProvider.overrideWithValue(fakeService)],
        child: const MaterialApp(home: SimulationScreen()),
      ),
    );

    await tester.pumpAndSettle();

    // Verify initial state: 40:00 countdown timer, question 1 of 2
    expect(find.text('40:00'), findsOneWidget);
    expect(find.text('Pregunta 1 de 2'), findsOneWidget);
    expect(find.text('Sin responder'), findsOneWidget);

    // Verify "Siguiente" button is enabled even though no answer is selected
    final siguienteBtn = find.widgetWithText(FilledButton, 'Siguiente');
    expect(siguienteBtn, findsOneWidget);
    expect(tester.widget<FilledButton>(siguienteBtn).onPressed, isNotNull);

    // Tap "Siguiente" to skip without answering
    await tester.tap(siguienteBtn);
    await tester.pumpAndSettle();

    // Now on question 2
    expect(find.text('Pregunta 2 de 2'), findsOneWidget);

    // Open question navigator sheet
    await tester.tap(find.byIcon(Icons.grid_view_rounded).first);
    await tester.pumpAndSettle();

    expect(find.text('Navegación de Preguntas'), findsOneWidget);
    expect(find.text('Respondidas (0)'), findsOneWidget);
    expect(find.text('Pendientes (2)'), findsOneWidget);

    // Tap on question 1 chip in the grid to jump back
    await tester.tap(find.text('1'));
    await tester.pumpAndSettle();

    // Verify we navigated back to question 1
    expect(find.text('Pregunta 1 de 2'), findsOneWidget);
  });
}

class FakeQuestionService extends QuestionService {
  FakeQuestionService(this.data);
  final SimulacrumData data;

  @override
  Future<SimulacrumData> getSimulacrumQuestions() async => data;
}
