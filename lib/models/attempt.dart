class AttemptAnswer {
  final int id;
  final int attemptId;
  final int questionId;
  final int selectedOption;
  final bool isCorrect;
  final AttemptOption option;
  final AttemptQuestion? question;

  const AttemptAnswer({
    required this.id,
    required this.attemptId,
    required this.questionId,
    required this.selectedOption,
    required this.isCorrect,
    required this.option,
    this.question,
  });

  factory AttemptAnswer.fromJson(Map<String, dynamic> json) {
    return AttemptAnswer(
      id: json['id'] as int,
      attemptId: json['attempt_id'] as int,
      questionId: json['question_id'] as int,
      selectedOption: json['selected_option'] as int,
      isCorrect: json['is_correct'] as bool? ?? false,
      option: AttemptOption.fromJson(json['option'] as Map<String, dynamic>),
      question: json['question'] != null
          ? AttemptQuestion.fromJson(json['question'] as Map<String, dynamic>)
          : null,
    );
  }
}

class AttemptOption {
  final int id;
  final String optionText;
  final bool isCorrect;

  const AttemptOption({
    required this.id,
    required this.optionText,
    required this.isCorrect,
  });

  factory AttemptOption.fromJson(Map<String, dynamic> json) {
    return AttemptOption(
      id: json['id'] as int,
      optionText: json['option_text'] ?? '',
      isCorrect: json['is_correct'] as bool? ?? false,
    );
  }
}

class AttemptQuestion {
  final int id;
  final String question;
  final List<AttemptOption> options;

  const AttemptQuestion({
    required this.id,
    required this.question,
    required this.options,
  });

  factory AttemptQuestion.fromJson(Map<String, dynamic> json) {
    return AttemptQuestion(
      id: json['id'] as int,
      question: json['question'] ?? '',
      options: (json['options'] as List<dynamic>? ?? [])
          .map(
            (option) => AttemptOption.fromJson(option as Map<String, dynamic>),
          )
          .toList(),
    );
  }
}

class Attempt {
  final int id;
  final int userId;
  final DateTime? startedAt;
  final DateTime? finishedAt;
  final int totalQuestions;
  final int correctAnswers;
  final int wrongAnswers;
  final double score;
  final bool approved;
  final List<AttemptAnswer> answers;

  const Attempt({
    required this.id,
    required this.userId,
    required this.startedAt,
    required this.finishedAt,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.wrongAnswers,
    required this.score,
    required this.approved,
    required this.answers,
  });

  factory Attempt.fromJson(Map<String, dynamic> json) {
    return Attempt(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      startedAt: json['started_at'] != null
          ? DateTime.tryParse(json['started_at'] as String)
          : null,
      finishedAt: json['finished_at'] != null
          ? DateTime.tryParse(json['finished_at'] as String)
          : null,
      totalQuestions: json['total_questions'] as int? ?? 0,
      correctAnswers: json['correct_answers'] as int? ?? 0,
      wrongAnswers: json['wrong_answers'] as int? ?? 0,
      score: double.tryParse(json['score']?.toString() ?? '0') ?? 0,
      approved: json['approved'] as bool? ?? false,
      answers: (json['answers'] as List<dynamic>? ?? [])
          .map(
            (answer) => AttemptAnswer.fromJson(answer as Map<String, dynamic>),
          )
          .toList(),
    );
  }
}
