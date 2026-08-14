import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/question.dart';
import '../services/question_service.dart';

final questionServiceProvider = Provider<QuestionService>((ref) {
  return QuestionService();
});

final questionProvider =
    StateNotifierProvider<QuestionNotifier, AsyncValue<List<Question>>>((ref) {
      return QuestionNotifier(ref.read(questionServiceProvider));
    });

class QuestionNotifier extends StateNotifier<AsyncValue<List<Question>>> {
  final QuestionService _questionService;

  int _currentPage = 1;
  int _limit = 10;
  int _totalPages = 1;

  QuestionNotifier(this._questionService) : super(const AsyncValue.data([]));

  int get currentPage => _currentPage;
  int get limit => _limit;
  int get totalPages => _totalPages;

  Future<void> loadQuestions({int? page, int? limit}) async {
    if (page != null) _currentPage = page;
    if (limit != null) _limit = limit;

    state = const AsyncValue.loading();
    try {
      final questionPage = await _questionService.getQuestions(
        page: _currentPage,
        limit: _limit,
      );
      _totalPages = questionPage.totalPages;
      state = AsyncValue.data(questionPage.questions);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> nextPage() async {
    if (_currentPage < _totalPages) {
      await loadQuestions(page: _currentPage + 1);
    }
  }

  Future<void> previousPage() async {
    if (_currentPage > 1) {
      await loadQuestions(page: _currentPage - 1);
    }
  }

  Future<void> changeLimit(int newLimit) async {
    await loadQuestions(page: 1, limit: newLimit);
  }
}
