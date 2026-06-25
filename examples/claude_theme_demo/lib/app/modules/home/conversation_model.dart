class ConversationModel {
  final String id;
  final String title;
  final String lastMessage;
  final DateTime updatedAt;
  final bool isStarred;

  const ConversationModel({
    required this.id,
    required this.title,
    required this.lastMessage,
    required this.updatedAt,
    this.isStarred = false,
  });

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    return ConversationModel(
      id: json['id'].toString(),
      title: json['title'] as String? ?? 'Untitled',
      lastMessage: json['last_message'] as String? ?? '',
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String) ?? DateTime.now()
          : DateTime.now(),
      isStarred: json['is_starred'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'last_message': lastMessage,
        'updated_at': updatedAt.toIso8601String(),
        'is_starred': isStarred,
      };

  String get timeAgo {
    final now = DateTime.now();
    final diff = now.isBefore(updatedAt) ? Duration.zero : now.difference(updatedAt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${(diff.inDays / 7).floor()}w ago';
  }
}
