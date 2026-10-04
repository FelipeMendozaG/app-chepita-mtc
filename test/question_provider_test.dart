import 'package:flutter_test/flutter_test.dart';

import 'package:app_chepita_mtc/models/question.dart';
import 'package:app_chepita_mtc/models/question_page.dart';
import 'package:app_chepita_mtc/providers/question_provider.dart';
import 'package:app_chepita_mtc/services/question_service.dart';

void main() {
  group('QuestionNotifier', () {
    late FakeQuestionService questionService;
    late QuestionNotifier notifier;

    setUp(() {
      questionService = FakeQuestionService();
      notifier = QuestionNotifier(questionService);
    });

    tearDown(() => notifier.dispose());

    test('loads questions with the initial page and limit', () async {
      await notifier.loadQuestions();

      expect(questionService.requests, [(1, 10)]);
      expect(notifier.state.value, [question]);
      expect(notifier.currentPage, 1);
      expect(notifier.limit, 10);
      expect(notifier.totalPages, 3);
    });

    test('moves between pages and does not pass the boundaries', () async {
      await notifier.loadQuestions();

      await notifier.previousPage();
      expect(questionService.requests, [(1, 10)]);

      await notifier.nextPage();
      expect(notifier.currentPage, 2);
      await notifier.nextPage();
      expect(notifier.currentPage, 3);
      await notifier.nextPage();
      expect(notifier.currentPage, 3);

      await notifier.previousPage();
      expect(notifier.currentPage, 2);
      expect(questionService.requests, [(1, 10), (2, 10), (3, 10), (2, 10)]);
    });

    test('changing the limit reloads the first page', () async {
      await notifier.loadQuestions(page: 3);
      await notifier.changeLimit(25);

      expect(questionService.requests, [(3, 10), (1, 25)]);
      expect(notifier.currentPage, 1);
      expect(notifier.limit, 25);
    });

    test('reports service failures as AsyncError', () async {
      questionService.error = Exception('offline');

      await notifier.loadQuestions();

      expect(notifier.state.error, isA<Exception>());
    });
  });
}

final question = Question(
  id: 10,
  number: 1,
  subject: 'Reglas de tránsito',
  topic: 'Señales',
  licenseCategory: 'A-I',
  question: '¿Qué indica esta señal?',
  options: const [],
);

class FakeQuestionService extends QuestionService {
  final List<(int, int)> requests = [];
  Object? error;

  @override
  Future<QuestionPage> getQuestions({
    required int page,
    required int limit,
  }) async {
    requests.add((page, limit));
    if (error != null) throw error!;
    return QuestionPage(
      total: 30,
      page: page,
      limit: limit,
      totalPages: 3,
      questions: [question],
    );
  }
}
