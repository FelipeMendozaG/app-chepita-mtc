class QuestionOption {
  final int id;
  final int optionNumber;
  final String optionText;
  final bool isCorrect;

  const QuestionOption({
    required this.id,
    required this.optionNumber,
    required this.optionText,
    required this.isCorrect,
  });

  factory QuestionOption.fromJson(Map<String, dynamic> json) {
    return QuestionOption(
      id: json['id'] as int,
      optionNumber: json['option_number'] as int,
      optionText: json['option_text'] ?? '',
      isCorrect: json['is_correct'] as bool? ?? false,
    );
  }
}

class Question {
  final int id;
  final int number;
  final String subject;
  final String topic;
  final String licenseCategory;
  final String question;
  final String? imageUrl;
  final String? explanation;
  final List<QuestionOption> options;

  const Question({
    required this.id,
    required this.number,
    required this.subject,
    required this.topic,
    required this.licenseCategory,
    required this.question,
    this.imageUrl,
    this.explanation,
    required this.options,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['id'] as int,
      number: json['number'] as int,
      subject: json['subject'] ?? '',
      topic: json['topic'] ?? '',
      licenseCategory: json['license_category'] ?? '',
      question: json['question'] ?? '',
      imageUrl: json['image_url'],
      explanation: json['explanation'],
      options: (json['options'] as List<dynamic>? ?? [])
          .map(
            (option) => QuestionOption.fromJson(option as Map<String, dynamic>),
          )
          .toList(),
    );
  }
}
