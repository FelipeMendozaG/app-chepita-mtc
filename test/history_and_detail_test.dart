import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app_chepita_mtc/models/attempt.dart';
import 'package:app_chepita_mtc/providers/attempt_provider.dart';
import 'package:app_chepita_mtc/screens/attempt_detail_screen.dart';
import 'package:app_chepita_mtc/screens/history_screen.dart';
import 'package:app_chepita_mtc/services/attempt_service.dart';

void main() {
  testWidgets(
    'HistoryScreen renders stats dashboard and filters by approved/failed',
    (WidgetTester tester) async {
      final attempts = [
        Attempt(
          id: 1,
          userId: 1,
          startedAt: DateTime(2026, 9, 1, 10, 0),
          finishedAt: DateTime(2026, 9, 1, 10, 35),
          totalQuestions: 40,
          correctAnswers: 36,
          wrongAnswers: 4,
          score: 90.0,
          approved: true,
          answers: const [],
        ),
        Attempt(
          id: 2,
          userId: 1,
          startedAt: DateTime(2026, 9, 2, 11, 0),
          finishedAt: DateTime(2026, 9, 2, 11, 40),
          totalQuestions: 40,
          correctAnswers: 30,
          wrongAnswers: 10,
          score: 75.0,
          approved: false,
          answers: const [],
        ),
      ];

      final fakeService = FakeAttemptService(attempts);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [attemptServiceProvider.overrideWithValue(fakeService)],
          child: const MaterialApp(home: HistoryScreen()),
        ),
      );

      await tester.pumpAndSettle();

      // Dashboard stats header
      expect(find.text('Rendimiento Global'), findsOneWidget);
      expect(find.text('Simulacros'), findsOneWidget);
      expect(find.text('Aprobados'), findsWidgets);
      expect(find.text('Tasa de Éxito'), findsOneWidget);
      expect(find.text('50%'), findsOneWidget); // 1 approved out of 2 = 50%
      expect(find.text('Mejor Nota'), findsOneWidget);
      expect(find.text('90'), findsWidgets);

      // Both attempts displayed initially
      expect(find.text('Intento #1'), findsOneWidget);
      expect(find.text('Intento #2'), findsOneWidget);

      // Filter by Aprobados (tap "Aprobados (1)")
      await tester.tap(find.text('Aprobados (1)'));
      await tester.pumpAndSettle();

      expect(find.text('Intento #1'), findsOneWidget);
      expect(find.text('Intento #2'), findsNothing);

      // Filter by Desaprobados (tap "Desaprobados (1)")
      await tester.tap(find.text('Desaprobados (1)'));
      await tester.pumpAndSettle();

      expect(find.text('Intento #1'), findsNothing);
      expect(find.text('Intento #2'), findsOneWidget);
    },
  );

  testWidgets(
    'AttemptDetailScreen filters answers by incorrect and correct tabs',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final attempt = Attempt(
        id: 99,
        userId: 1,
        startedAt: DateTime(2026, 9, 1, 10, 0),
        finishedAt: DateTime(2026, 9, 1, 10, 35),
        totalQuestions: 2,
        correctAnswers: 1,
        wrongAnswers: 1,
        score: 50.0,
        approved: false,
        answers: [
          const AttemptAnswer(
            id: 1,
            attemptId: 99,
            questionId: 10,
            selectedOption: 1,
            isCorrect: true,
            option: AttemptOption(
              id: 1,
              optionText: 'Opción acertada',
              isCorrect: true,
            ),
            question: AttemptQuestion(
              id: 10,
              question: '¿Pregunta 1 superada?',
              options: [],
            ),
          ),
          const AttemptAnswer(
            id: 2,
            attemptId: 99,
            questionId: 11,
            selectedOption: 2,
            isCorrect: false,
            option: AttemptOption(
              id: 2,
              optionText: 'Opción fallida',
              isCorrect: false,
            ),
            question: AttemptQuestion(
              id: 11,
              question: '¿Pregunta 2 errada?',
              options: [],
            ),
          ),
        ],
      );

      final fakeService = FakeAttemptService([attempt]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [attemptServiceProvider.overrideWithValue(fakeService)],
          child: const MaterialApp(home: AttemptDetailScreen(attemptId: 99)),
        ),
      );

      await tester.pumpAndSettle();

      // MTC note indicator
      expect(find.text('Nota mínima MTC: 35 de 40 preguntas'), findsOneWidget);

      // Both questions visible initially
      expect(find.text('¿Pregunta 1 superada?'), findsOneWidget);
      expect(find.text('¿Pregunta 2 errada?'), findsOneWidget);

      // Filter by Incorrectas (tap "Incorrectas (1)")
      final incorrectTab = find.text('Incorrectas (1)');
      await tester.ensureVisible(incorrectTab);
      await tester.tap(incorrectTab);
      await tester.pumpAndSettle();

      expect(find.text('¿Pregunta 1 superada?'), findsNothing);
      expect(find.text('¿Pregunta 2 errada?'), findsOneWidget);

      // Filter by Correctas (tap "Correctas (1)")
      final correctTab = find.text('Correctas (1)');
      await tester.ensureVisible(correctTab);
      await tester.tap(correctTab);
      await tester.pumpAndSettle();

      expect(find.text('¿Pregunta 1 superada?'), findsOneWidget);
      expect(find.text('¿Pregunta 2 errada?'), findsNothing);
    },
  );
}

class FakeAttemptService extends AttemptService {
  FakeAttemptService(this.attempts);
  final List<Attempt> attempts;

  @override
  Future<List<Attempt>> getAttempts() async => attempts;

  @override
  Future<Attempt> getAttemptDetail(int attemptId) async {
    return attempts.firstWhere((a) => a.id == attemptId);
  }
}
