import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import '../models/discussion.dart';
import 'session_expired_exception.dart';
import 'storage_service.dart';

class DiscussionService {
  String get _baseUrl {
    final apiUrl = dotenv.env['API_URL'] ?? 'http://localhost:4005/api';
    return '$apiUrl/v1/discussions';
  }

  static Uri? resolveImageUri(String? imageUrl) {
    if (imageUrl == null || imageUrl.trim().isEmpty) return null;
    final value = imageUrl.trim();
    if (value.startsWith('http://') || value.startsWith('https://')) {
      return Uri.parse(value);
    }
    final apiUrl = dotenv.env['API_URL'] ?? 'http://localhost:4005/api';
    return Uri.parse(apiUrl).resolve(value);
  }

  Future<List<Discussion>> getDiscussions() async {
    final response = await _request('GET', Uri.parse(_baseUrl));
    final data = _decode(response);
    _checkResponse(response, data);
    final items = data['data'] is List ? data['data'] as List<dynamic> : [];
    return items
        .whereType<Map<String, dynamic>>()
        .map(Discussion.fromJson)
        .toList();
  }

  Future<Discussion> createDiscussion({
    required String title,
    required String content,
    String? imagePath,
  }) async {
    final token = await StorageService().getToken();
    final request = http.MultipartRequest('POST', Uri.parse(_baseUrl));
    request.headers['Authorization'] = 'Bearer $token';
    request.fields.addAll({'title': title, 'content': content});
    if (imagePath != null) {
      request.files.add(await http.MultipartFile.fromPath('image', imagePath));
    }
    final response = await http.Response.fromStream(await request.send());
    final data = _decode(response);
    _checkResponse(response, data);
    return Discussion.fromJson(data['data'] as Map<String, dynamic>);
  }

  Future<void> reply(int id, String reply) =>
      _mutate('POST', '$id/reply', {'reply': reply});
  Future<void> close(int id, String reason) =>
      _mutate('PATCH', '$id/close', {'closed_reason': reason});
  Future<void> report(int id, String reason) =>
      _mutate('POST', '$id/report', {'reason': reason});

  Future<void> _mutate(
    String method,
    String path,
    Map<String, String> body,
  ) async {
    final response = await _request(
      method,
      Uri.parse('$_baseUrl/$path'),
      body: body,
    );
    final data = _decode(response);
    _checkResponse(response, data);
  }

  Future<http.Response> _request(
    String method,
    Uri uri, {
    Map<String, String>? body,
  }) async {
    final token = await StorageService().getToken();
    final headers = {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
    if (method == 'GET') {
      return http.get(uri, headers: headers);
    }
    if (method == 'POST') {
      return http.post(uri, headers: headers, body: jsonEncode(body));
    }
    return http.patch(uri, headers: headers, body: jsonEncode(body));
  }

  Map<String, dynamic> _decode(http.Response response) {
    final decoded = response.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(response.body);
    return decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
  }

  void _checkResponse(http.Response response, Map<String, dynamic> data) {
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    if (response.statusCode == 401) throw SessionExpiredException();
    throw Exception(data['message'] ?? data['error'] ?? 'Error en debates');
  }
}
