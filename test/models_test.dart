import 'package:flutter_test/flutter_test.dart';

import 'package:app_chepita_mtc/models/attempt.dart';
import 'package:app_chepita_mtc/models/question.dart';
import 'package:app_chepita_mtc/models/question_page.dart';
import 'package:app_chepita_mtc/models/simulacrum_data.dart';
import 'package:app_chepita_mtc/models/user.dart';

void main() {
  group('Question.fromJson', () {
    test('parses options and nullable fields', () {
      final question = Question.fromJson({
        'id': 7,
        'number': 3,
        'subject': 'Normas de tránsito',
        'topic': 'Señales',
        'license_category': 'A-I',
        'question': '¿Qué indica la señal?',
        'image_url': '/images/sign.webp',
        'explanation': 'Indica una curva.',
        'options': [
          {
            'id': 21,
            'option_number': 1,
            'option_text': 'Curva a la derecha',
            'is_correct': true,
          },
        ],
      });

      expect(question.id, 7);
      expect(question.number, 3);
      expect(question.imageUrl, '/images/sign.webp');
      expect(question.explanation, 'Indica una curva.');
      expect(question.options, hasLength(1));
      expect(question.options.single.optionNumber, 1);
      expect(question.options.single.isCorrect, isTrue);
    });

    test('defaults optional text and options when absent', () {
      final question = Question.fromJson({'id': 1, 'number': 1});

      expect(question.subject, isEmpty);
      expect(question.topic, isEmpty);
      expect(question.licenseCategory, isEmpty);
      expect(question.question, isEmpty);
      expect(question.imageUrl, isNull);
      expect(question.explanation, isNull);
      expect(question.options, isEmpty);
    });
  });

  test('QuestionPage parses pagination and nested questions', () {
    final page = QuestionPage.fromJson({
      'total': 1,
      'page': 2,
      'limit': 10,
      'totalPages': 4,
      'data': [
        {'id': 1, 'number': 9},
      ],
    });

    expect(page.total, 1);
    expect(page.page, 2);
    expect(page.limit, 10);
    expect(page.totalPages, 4);
    expect(page.questions.single.id, 1);
  });

  test('SimulacrumData parses attempt id and questions', () {
    final simulacrum = SimulacrumData.fromJson({
      'attempt_id': 55,
      'questions': [
        {'id': 2, 'number': 1},
      ],
    });

    expect(simulacrum.idAttempt, 55);
    expect(simulacrum.questions.single.id, 2);
  });

  group('Attempt.fromJson', () {
    test('parses score, dates, and nested answers', () {
      final attempt = Attempt.fromJson({
        'id': 8,
        'user_id': 3,
        'started_at': '2026-09-20T10:00:00.000Z',
        'finished_at': '2026-09-20T10:30:00.000Z',
        'total_questions': 1,
        'correct_answers': 1,
        'wrong_answers': 0,
        'score': '100.0',
        'approved': true,
        'answers': [
          {
            'id': 12,
            'attempt_id': 8,
            'question_id': 4,
            'selected_option': 6,
            'is_correct': true,
            'option': {
              'id': 6,
              'option_text': 'Respuesta correcta',
              'is_correct': true,
            },
            'question': {
              'id': 4,
              'question': 'Pregunta de prueba',
              'options': [],
            },
          },
        ],
      });

      expect(attempt.id, 8);
      expect(attempt.startedAt, DateTime.parse('2026-09-20T10:00:00.000Z'));
      expect(attempt.finishedAt, DateTime.parse('2026-09-20T10:30:00.000Z'));
      expect(attempt.score, 100);
      expect(attempt.approved, isTrue);
      expect(attempt.answers.single.option.optionText, 'Respuesta correcta');
      expect(attempt.answers.single.question?.question, 'Pregunta de prueba');
    });

    test('uses defaults for nullable summary values', () {
      final attempt = Attempt.fromJson({
        'id': 8,
        'user_id': 3,
        'started_at': null,
        'finished_at': null,
        'score': 'invalid',
      });

      expect(attempt.startedAt, isNull);
      expect(attempt.finishedAt, isNull);
      expect(attempt.totalQuestions, 0);
      expect(attempt.correctAnswers, 0);
      expect(attempt.wrongAnswers, 0);
      expect(attempt.score, 0);
      expect(attempt.approved, isFalse);
      expect(attempt.answers, isEmpty);
    });
  });

  test('User supports JSON serialization and missing optional values', () {
    const user = User(id: 5, name: 'Ana', email: 'ana@example.com', token: 't');
    final restored = User.fromJson(user.toJson());
    final minimal = User.fromJson({});

    expect(restored.id, 5);
    expect(restored.name, 'Ana');
    expect(restored.email, 'ana@example.com');
    expect(restored.token, 't');
    expect(minimal.id, isNull);
    expect(minimal.name, isEmpty);
    expect(minimal.email, isEmpty);
    expect(minimal.token, isNull);
  });
}
