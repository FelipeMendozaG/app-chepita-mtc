import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import '../models/attempt.dart';
import 'session_expired_exception.dart';
import 'session_manager.dart';
import 'storage_service.dart';

class AttemptService {
  static String get _baseUrl {
    final apiUrl = dotenv.env['API_URL'] ?? 'http://localhost:4005/api';
    return '$apiUrl/v1/attempt';
  }

  Future<List<Attempt>> getAttempts() async {
    final token = await StorageService().getToken();
    final response = await http.get(
      Uri.parse(_baseUrl),
      headers: {
        'content-type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final attempts = data['data'] as List<dynamic>? ?? [];
      return attempts
          .map((attempt) => Attempt.fromJson(attempt as Map<String, dynamic>))
          .toList();
    }

    if (response.statusCode == 401 && data['error'] == 'ERROR_NO_VALID_TOKEN') {
      await SessionManager.handleSessionExpired();
      throw SessionExpiredException();
    }

    throw Exception(data['message'] ?? 'Error al obtener el historial');
  }

  Future<Attempt> getAttemptDetail(int attemptId) async {
    final token = await StorageService().getToken();
    final response = await http.get(
      Uri.parse('$_baseUrl/$attemptId'),
      headers: {
        'content-type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final dataMap = data['data'] as Map<String, dynamic>;
      return Attempt.fromJson(dataMap);
    }

    if (response.statusCode == 401 && data['error'] == 'ERROR_NO_VALID_TOKEN') {
      await SessionManager.handleSessionExpired();
      throw SessionExpiredException();
    }

    throw Exception(
      data['message'] ?? 'Error al obtener el detalle del intento',
    );
  }
}
