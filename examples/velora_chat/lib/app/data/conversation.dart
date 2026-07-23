/// A single conversation thread, backed by the `conversations` table.
///
/// `fromMap`/`toMap` keys mirror the column names exactly, so a `Conversation`
/// round-trips straight through `VeloraTable<Conversation, String>` without
/// any translation layer.
class Conversation {
  final String id;
  final String title;
  final String? lastMessage;
  final DateTime? lastAt;
  final int unread;

  const Conversation({
    required this.id,
    required this.title,
    this.lastMessage,
    this.lastAt,
    this.unread = 0,
  });

  factory Conversation.fromMap(Map<String, dynamic> row) {
    final lastAtMillis = row['last_at'];
    return Conversation(
      id: row['id']?.toString() ?? '',
      title: row['title']?.toString() ?? '',
      lastMessage: row['last_message']?.toString(),
      lastAt: lastAtMillis == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(
              lastAtMillis is int
                  ? lastAtMillis
                  : int.parse(lastAtMillis.toString()),
            ),
      unread: row['unread'] == null
          ? 0
          : (row['unread'] is int
              ? row['unread'] as int
              : int.parse(row['unread'].toString())),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'last_message': lastMessage,
      'last_at': lastAt?.millisecondsSinceEpoch,
      'unread': unread,
    };
  }

  Conversation copyWith({
    String? title,
    String? lastMessage,
    DateTime? lastAt,
    int? unread,
  }) {
    return Conversation(
      id: id,
      title: title ?? this.title,
      lastMessage: lastMessage ?? this.lastMessage,
      lastAt: lastAt ?? this.lastAt,
      unread: unread ?? this.unread,
    );
  }
}
