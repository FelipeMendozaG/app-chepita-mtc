import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import '../models/driving_recommendation.dart';

class RecommendationAuthException implements Exception {
  final String message;

  RecommendationAuthException([this.message = 'No autorizado']);

  @override
  String toString() => message;
}

class RecommendationServerException implements Exception {
  final String message;

  RecommendationServerException([this.message = 'Error del servidor']);

  @override
  String toString() => message;
}

class RecommendationService {
  static String get _baseUrl {
    final apiUrl = dotenv.env['API_URL'] ?? 'http://localhost:4005/api';
    return '$apiUrl/v1/recommendation';
  }

  static Uri? resolveImageUri(String? imageUrl) {
    if (imageUrl == null || imageUrl.trim().isEmpty) {
      return null;
    }

    final normalized = imageUrl.trim();
    if (normalized.startsWith('http://') || normalized.startsWith('https://')) {
      return Uri.parse(normalized);
    }

    final apiUrl = dotenv.env['API_URL'] ?? 'http://localhost:4005/api';
    return Uri.parse(apiUrl).resolve(normalized);
  }

  Future<DrivingRecommendation?> fetchRecommendation({
    required String token,
    String? category,
  }) async {
    final baseUri = Uri.parse(_baseUrl);
    final uri = category == null || category.trim().isEmpty
        ? baseUri
        : baseUri.replace(queryParameters: {'category': category});

    final response = await http.get(
      uri,
      headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
    );

    final decoded = response.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(response.body);
    final body = decoded is Map<String, dynamic>
        ? decoded
        : <String, dynamic>{};

    if (response.statusCode == 200) {
      final dynamic data = body['data'];
      if (data == null) {
        return null;
      }

      if (data is Map<String, dynamic>) {
        return DrivingRecommendation.fromJson(data);
      }

      if (data is List &&
          data.isNotEmpty &&
          data.first is Map<String, dynamic>) {
        return DrivingRecommendation.fromJson(
          data.first as Map<String, dynamic>,
        );
      }

      return null;
    }

    if (response.statusCode == 401) {
      final error = body['error'];
      if (error == 'ERROR_NO_EXISTS_TOKEN' || error == 'ERROR_NO_VALID_TOKEN') {
        throw RecommendationAuthException(error.toString());
      }
      throw RecommendationAuthException('Token inválido o no autorizado');
    }

    if (response.statusCode >= 500) {
      throw RecommendationServerException(
        body['message'] ?? 'Error del servidor al cargar la recomendación',
      );
    }

    throw Exception(body['message'] ?? 'Error al cargar la recomendación');
  }
}
