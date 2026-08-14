import 'question.dart';

class QuestionPage {
  final int total;
  final int page;
  final int limit;
  final int totalPages;
  final List<Question> questions;

  const QuestionPage({
    required this.total,
    required this.page,
    required this.limit,
    required this.totalPages,
    required this.questions,
  });

  factory QuestionPage.fromJson(Map<String, dynamic> json) {
    return QuestionPage(
      total: json['total'] as int,
      page: json['page'] as int,
      limit: json['limit'] as int,
      totalPages: json['totalPages'] as int,
      questions: (json['data'] as List<dynamic>? ?? [])
          .map(
            (question) => Question.fromJson(question as Map<String, dynamic>),
          )
          .toList(),
    );
  }
}
