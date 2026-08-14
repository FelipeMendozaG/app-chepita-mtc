import 'question.dart';

class SimulacrumData {
  final int idAttempt;
  final List<Question> questions;

  const SimulacrumData({required this.idAttempt, required this.questions});

  factory SimulacrumData.fromJson(Map<String, dynamic> json) {
    return SimulacrumData(
      idAttempt: json['attempt_id'] as int,
      questions: (json['questions'] as List<dynamic>? ?? [])
          .map(
            (question) => Question.fromJson(question as Map<String, dynamic>),
          )
          .toList(),
    );
  }
}
