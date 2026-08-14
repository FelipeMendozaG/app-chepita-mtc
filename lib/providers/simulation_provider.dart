import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/question.dart';
import '../services/question_service.dart';
import 'question_provider.dart';

final simulationProvider =
    StateNotifierProvider<SimulationNotifier, AsyncValue<List<Question>>>((
      ref,
    ) {
      return SimulationNotifier(ref.read(questionServiceProvider));
    });

class SimulationNotifier extends StateNotifier<AsyncValue<List<Question>>> {
  final QuestionService _questionService;

  int _currentIndex = 0;
  int? _idAttempt;
  final Map<int, int> _selectedAnswers = {};

  SimulationNotifier(this._questionService) : super(const AsyncValue.data([]));

  int get currentIndex => _currentIndex;
  int? get idAttempt => _idAttempt;
  int get totalQuestions => state.value?.length ?? 0;
  int get answeredCount => _selectedAnswers.length;

  double get progress {
    if (totalQuestions == 0) return 0;
    return (_currentIndex + 1) / totalQuestions;
  }

  int? selectedAnswerFor(int questionId) => _selectedAnswers[questionId];

  Map<int, int> get selectedAnswers => Map.unmodifiable(_selectedAnswers);

  Future<void> startSimulation() async {
    state = const AsyncValue.loading();
    try {
      final simulacrumData = await _questionService.getSimulacrumQuestions();
      _idAttempt = simulacrumData.idAttempt;
      _currentIndex = 0;
      _selectedAnswers.clear();
      state = AsyncValue.data(simulacrumData.questions);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  void selectAnswer(int questionId, int optionId) {
    _selectedAnswers[questionId] = optionId;
    state = AsyncValue.data(state.value ?? []);
  }

  void nextQuestion() {
    if (_currentIndex < totalQuestions - 1) {
      _currentIndex++;
      state = AsyncValue.data(state.value ?? []);
    }
  }

  void previousQuestion() {
    if (_currentIndex > 0) {
      _currentIndex--;
      state = AsyncValue.data(state.value ?? []);
    }
  }
}
