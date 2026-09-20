class DrivingRecommendation {
  final int? id;
  final String title;
  final String? category;
  final String content;
  final String? imageUrl;
  final bool isActive;
  final DateTime createdAt;

  const DrivingRecommendation({
    required this.id,
    required this.title,
    required this.category,
    required this.content,
    required this.imageUrl,
    required this.isActive,
    required this.createdAt,
  });

  factory DrivingRecommendation.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'];
    final rawCreatedAt = json['created_at'];

    return DrivingRecommendation(
      id: rawId is int ? rawId : int.tryParse(rawId?.toString() ?? ''),
      title: (json['title'] ?? '').toString(),
      category: json['category']?.toString(),
      content: (json['content'] ?? '').toString(),
      imageUrl: json['image_url']?.toString(),
      isActive: json['is_active'] is bool ? json['is_active'] as bool : false,
      createdAt: _parseCreatedAt(rawCreatedAt),
    );
  }

  static DateTime _parseCreatedAt(dynamic value) {
    if (value is String && value.trim().isNotEmpty) {
      try {
        return DateTime.parse(value).toUtc();
      } catch (_) {
        return DateTime.now();
      }
    }

    return DateTime.now();
  }
}
