import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app_chepita_mtc/models/attempt.dart';
import 'package:app_chepita_mtc/models/question.dart';
import 'package:app_chepita_mtc/models/question_page.dart';
import 'package:app_chepita_mtc/providers/attempt_provider.dart';
import 'package:app_chepita_mtc/providers/question_provider.dart';
import 'package:app_chepita_mtc/screens/attempt_detail_screen.dart';
import 'package:app_chepita_mtc/screens/questions_screen.dart';
import 'package:app_chepita_mtc/services/attempt_service.dart';
import 'package:app_chepita_mtc/services/question_service.dart';
import 'package:app_chepita_mtc/widgets/cards/question_explanation_tile.dart';
import 'package:app_chepita_mtc/widgets/cards/question_image_widget.dart';

void main() {
  testWidgets('QuestionExplanationTile expands and collapses on tap', (
    WidgetTester tester,
  ) async {
    const testExplanation =
      'La señal R-1 indica detención obligatoria total del vehículo.';

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: QuestionExplanationTile(
            explanation: testExplanation,
            initiallyExpanded: false,
          ),
        ),
      ),
    );

    // Header visible, content initially hidden/collapsed
    expect(find.text('Explicación'), findsOneWidget);
    expect(find.byIcon(Icons.keyboard_arrow_down), findsOneWidget);

    // Tap to expand
    await tester.tap(find.text('Explicación'));
    await tester.pumpAndSettle();

    expect(find.text(testExplanation), findsOneWidget);
    expect(find.byIcon(Icons.keyboard_arrow_up), findsOneWidget);

    // Tap to collapse
    await tester.tap(find.text('Explicación'));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.keyboard_arrow_down), findsOneWidget);
  });

  testWidgets('QuestionsScreen renders question image and explanation', (
    WidgetTester tester,
  ) async {
    final questions = [
      const Question(
        id: 10,
        number: 1,
        subject: 'Señalización',
        topic: 'Reglamentarias',
        licenseCategory: 'A-I',
        question: '¿Qué significa esta señal?',
        imageUrl: 'https://example.com/r-1.png',
        explanation: 'Indica la señal de PARE obligatoria.',
        options: [
          QuestionOption(
            id: 1,
            optionNumber: 1,
            optionText: 'Pare',
            isCorrect: true,
          ),
        ],
      ),
    ];

    final fakeService = FakeQuestionService(questions);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [questionServiceProvider.overrideWithValue(fakeService)],
        child: const MaterialApp(home: QuestionsScreen()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byType(QuestionImageWidget), findsOneWidget);
    expect(find.byType(QuestionExplanationTile), findsOneWidget);
    expect(find.text('Explicación'), findsOneWidget);
  });

  testWidgets('AttemptDetailScreen renders question image and explanation', (
    WidgetTester tester,
  ) async {
    final attempt = Attempt(
      id: 77,
      userId: 1,
      startedAt: DateTime(2026, 9, 1, 10, 0),
      finishedAt: DateTime(2026, 9, 1, 10, 35),
      totalQuestions: 1,
      correctAnswers: 0,
      wrongAnswers: 1,
      score: 0,
      approved: false,
      answers: [
        AttemptAnswer(
          id: 1,
          attemptId: 77,
          questionId: 10,
          selectedOption: 2,
          isCorrect: false,
          option: const AttemptOption(
            id: 2,
            optionText: 'Ceda el paso',
            isCorrect: false,
          ),
          question: const AttemptQuestion(
            id: 10,
            question: '¿Qué significa esta señal?',
            imageUrl: 'https://example.com/r-1.png',
            explanation: 'La señal octagonal roja siempre significa PARE.',
            options: [
              AttemptOption(id: 1, optionText: 'Pare', isCorrect: true),
              AttemptOption(
                id: 2,
                optionText: 'Ceda el paso',
                isCorrect: false,
              ),
            ],
          ),
        ),
      ],
    );

    final fakeAttemptService = FakeAttemptService(attempt);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          attemptServiceProvider.overrideWithValue(fakeAttemptService),
        ],
        child: const MaterialApp(
          home: AttemptDetailScreen(attemptId: 77),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byType(QuestionImageWidget), findsOneWidget);
    expect(find.byType(QuestionExplanationTile), findsOneWidget);
    // Since isCorrect is false, explanation is initially expanded
    expect(
      find.text('La señal octagonal roja siempre significa PARE.'),
      findsOneWidget,
    );
  });
}

class FakeQuestionService extends QuestionService {
  FakeQuestionService(this.questions);
  final List<Question> questions;

  @override
  Future<QuestionPage> getQuestions({int page = 1, int limit = 10}) async {
    return QuestionPage(
      total: questions.length,
      page: page,
      limit: limit,
      totalPages: 1,
      questions: questions,
    );
  }
}

class FakeAttemptService extends AttemptService {
  FakeAttemptService(this.attempt);
  final Attempt attempt;

  @override
  Future<Attempt> getAttemptDetail(int attemptId) async => attempt;
}
