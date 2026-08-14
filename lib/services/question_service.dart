import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import '../models/question_page.dart';
import '../models/simulacrum_data.dart';
import 'session_expired_exception.dart';
import 'session_manager.dart';
import 'storage_service.dart';

class QuestionService {
  static String get _baseUrl {
    final apiUrl = dotenv.env['API_URL'] ?? 'http://localhost:4005/api';
    return '$apiUrl/v1/question';
  }

  Future<QuestionPage> getQuestions({
    required int page,
    required int limit,
  }) async {
    final token = await StorageService().getToken();
    final response = await http.get(
      Uri.parse('$_baseUrl?page=$page&limit=$limit'),
      headers: {
        'content-type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final dataMap = data['data'] as Map<String, dynamic>;
      return QuestionPage.fromJson(dataMap);
    }

    if (response.statusCode == 401 && data['error'] == 'ERROR_NO_VALID_TOKEN') {
      await SessionManager.handleSessionExpired();
      throw SessionExpiredException();
    }

    throw Exception(data['message'] ?? 'Error al obtener preguntas');
  }

  Future<SimulacrumData> getSimulacrumQuestions() async {
    final token = await StorageService().getToken();
    final response = await http.get(
      Uri.parse('$_baseUrl/simulacrum'),
      headers: {
        'content-type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final dataMap = data['data'] as Map<String, dynamic>;
      return SimulacrumData.fromJson(dataMap);
    }

    if (response.statusCode == 401 && data['error'] == 'ERROR_NO_VALID_TOKEN') {
      await SessionManager.handleSessionExpired();
      throw SessionExpiredException();
    }

    throw Exception(
      data['message'] ?? 'Error al obtener preguntas del simulacro',
    );
  }

  Future<void> saveAttemptAnswers({
    required int attemptId,
    required Map<int, int> answers,
  }) async {
    print(answers);
    final token = await StorageService().getToken();
    final response = await http.post(
      Uri.parse('$_baseUrl/attempts/$attemptId'),
      headers: {
        'content-type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'answers': answers.entries
            .map(
              (entry) => {
                'question_id': entry.key,
                'selected_option': entry.value,
              },
            )
            .toList(),
      }),
    );

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }

    if (response.statusCode == 401 && data['error'] == 'ERROR_NO_VALID_TOKEN') {
      await SessionManager.handleSessionExpired();
      throw SessionExpiredException();
    }

    throw Exception(data['message'] ?? 'Error al guardar las respuestas');
  }
}
