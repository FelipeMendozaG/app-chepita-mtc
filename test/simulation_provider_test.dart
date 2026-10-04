import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app_chepita_mtc/models/question.dart';
import 'package:app_chepita_mtc/models/simulacrum_data.dart';
import 'package:app_chepita_mtc/providers/simulation_provider.dart';
import 'package:app_chepita_mtc/services/question_service.dart';

void main() {
  group('SimulationNotifier', () {
    late FakeQuestionService questionService;
    late SimulationNotifier notifier;

    setUp(() {
      questionService = FakeQuestionService(
        SimulacrumData(idAttempt: 42, questions: _questions),
      );
      notifier = SimulationNotifier(questionService);
    });

    tearDown(() => notifier.dispose());

    test('starts a simulation and resets prior answers', () async {
      notifier.selectAnswer(10, 101);
      notifier.nextQuestion();

      await notifier.startSimulation();

      expect(notifier.state.value, _questions);
      expect(notifier.idAttempt, 42);
      expect(notifier.currentIndex, 0);
      expect(notifier.answeredCount, 0);
      expect(notifier.selectedAnswerFor(10), isNull);
      expect(notifier.progress, 0.5);
    });

    test('selects answers and navigates within question bounds', () async {
      await notifier.startSimulation();

      notifier.selectAnswer(10, 101);
      notifier.selectAnswer(11, 112);
      notifier.nextQuestion();

      expect(notifier.currentIndex, 1);
      expect(notifier.progress, 1);
      expect(notifier.answeredCount, 2);
      expect(notifier.selectedAnswerFor(10), 101);
      expect(notifier.selectedAnswers, {10: 101, 11: 112});

      notifier.nextQuestion();
      expect(notifier.currentIndex, 1);

      notifier.previousQuestion();
      expect(notifier.currentIndex, 0);
      notifier.previousQuestion();
      expect(notifier.currentIndex, 0);
    });

    test('reports service failures as AsyncError', () async {
      questionService.error = Exception('offline');

      await notifier.startSimulation();

      expect(notifier.state.hasError, isTrue);
      expect(notifier.state.error, isA<Exception>());
    });
  });
}

final List<Question> _questions = [_question(10, 1), _question(11, 2)];

Question _question(int id, int number) {
  return Question(
    id: id,
    number: number,
    subject: 'Reglas de tránsito',
    topic: 'Señales',
    licenseCategory: 'A-I',
    question: 'Pregunta $number',
    options: const [],
  );
}

class FakeQuestionService extends QuestionService {
  FakeQuestionService(this.result);

  final SimulacrumData result;
  Object? error;

  @override
  Future<SimulacrumData> getSimulacrumQuestions() async {
    if (error != null) throw error!;
    return result;
  }
}
