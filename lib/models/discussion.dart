class DiscussionAuthor {
  final int? id;
  final String name;

  const DiscussionAuthor({this.id, required this.name});

  factory DiscussionAuthor.fromJson(Map<String, dynamic>? json) {
    return DiscussionAuthor(
      id: json?['id'] as int?,
      name: json?['name']?.toString() ?? 'Usuario',
    );
  }
}

class Discussion {
  final int id;
  final String title;
  final String content;
  final DiscussionAuthor author;
  final DateTime? createdAt;
  final String status;
  final String? imageUrl;
  final String? closedReason;

  const Discussion({
    required this.id,
    required this.title,
    required this.content,
    required this.author,
    required this.createdAt,
    required this.status,
    required this.imageUrl,
    required this.closedReason,
  });

  bool get isClosed => status.toLowerCase() == 'closed';

  factory Discussion.fromJson(Map<String, dynamic> json) {
    final authorJson = json['author'] is Map<String, dynamic>
        ? json['author'] as Map<String, dynamic>
        : null;
    return Discussion(
      id: _toInt(json['id']) ?? 0,
      title: json['title']?.toString() ?? 'Sin título',
      content: json['content']?.toString() ?? '',
      author: DiscussionAuthor.fromJson(authorJson),
      createdAt:
          DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.tryParse(json['createdAt']?.toString() ?? ''),
      status: json['status']?.toString() ?? 'open',
      imageUrl: json['image_url']?.toString() ?? json['imageUrl']?.toString(),
      closedReason:
          json['closed_reason']?.toString() ?? json['closedReason']?.toString(),
    );
  }

  static int? _toInt(dynamic value) =>
      value is int ? value : int.tryParse('$value');
}
