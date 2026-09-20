import 'package:flutter_test/flutter_test.dart';

import 'package:app_chepita_mtc/models/driving_recommendation.dart';

void main() {
  group('DrivingRecommendation', () {
    test('fromJson parses the payload safely and handles nullable fields', () {
      final recommendation = DrivingRecommendation.fromJson({
        'id': 24,
        'title': 'Límite de velocidad en carreteras para automóviles',
        'category': 'Límites de Velocidad',
        'content': 'En carreteras fuera de zonas urbanas, el límite máximo de velocidad para automóviles es de 100 km/h.',
        'image_url': '/uploads/recommendations/velocidad_carretera.webp',
        'is_active': true,
        'created_at': '2026-09-20T16:46:22.000Z',
      });

      expect(recommendation.id, 24);
      expect(recommendation.title,
          'Límite de velocidad en carreteras para automóviles');
      expect(recommendation.category, 'Límites de Velocidad');
      expect(recommendation.content,
          'En carreteras fuera de zonas urbanas, el límite máximo de velocidad para automóviles es de 100 km/h.');
      expect(recommendation.imageUrl,
          '/uploads/recommendations/velocidad_carretera.webp');
      expect(recommendation.isActive, isTrue);
      expect(recommendation.createdAt, isA<DateTime>());
    });

    test('fromJson defaults null values safely', () {
      final recommendation = DrivingRecommendation.fromJson({
        'id': null,
        'title': null,
        'category': null,
        'content': 'Contenido del consejo',
        'image_url': null,
        'is_active': false,
        'created_at': null,
      });

      expect(recommendation.id, isNull);
      expect(recommendation.title, isEmpty);
      expect(recommendation.category, isNull);
      expect(recommendation.content, 'Contenido del consejo');
      expect(recommendation.imageUrl, isNull);
      expect(recommendation.isActive, isFalse);
      expect(recommendation.createdAt, isA<DateTime>()); // ISO null fallback
    });
  });
}
