import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import '../models/user.dart';

class AuthService {
  static String get _baseUrl {
    final apiUrl = dotenv.env['API_URL'] ?? 'http://localhost:4005/api';
    return '$apiUrl/v1/auth';
  }

  Future<User> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse(_baseUrl),
      headers: {'content-type': 'application/json'},
      body: jsonEncode({'name': name, 'email': email, 'password': password}),
    );

    return _parseAuthResponse(response);
  }

  Future<User> login({required String email, required String password}) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/login'),
      headers: {'content-type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    return _parseAuthResponse(response);
  }

  User _parseAuthResponse(http.Response response) {
    final data = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final dataMap = data['data'] as Map<String, dynamic>;
      final userMap = dataMap['user'] as Map<String, dynamic>;
      final token = dataMap['token'] as String?;

      return User.fromJson({...userMap, 'token': token});
    } else {
      throw Exception(data['message'] ?? 'Error en la autenticación');
    }
  }
}
