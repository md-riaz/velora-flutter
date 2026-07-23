/// A single chat message, backed by the `messages` table.
///
/// [status] is `'pending'` while a message is sitting in the offline write
/// outbox waiting to be delivered, and `'sent'` once the (mock) server has
/// acknowledged it. [outgoing] distinguishes messages this device sent from
/// ones the other side sent (stored as `1`/`0`, exposed here as a `bool`).
class Message {
  final String id;
  final String conversationId;
  final String body;
  final bool outgoing;
  final String status;
  final DateTime createdAt;

  const Message({
    required this.id,
    required this.conversationId,
    required this.body,
    required this.outgoing,
    required this.status,
    required this.createdAt,
  });

  bool get isPending => status == 'pending';

  factory Message.fromMap(Map<String, dynamic> row) {
    final createdAtMillis = row['created_at'];
    return Message(
      id: row['id']?.toString() ?? '',
      conversationId: row['conversation_id']?.toString() ?? '',
      body: row['body']?.toString() ?? '',
      outgoing: row['outgoing'] == 1 || row['outgoing'] == true,
      status: row['status']?.toString() ?? 'pending',
      createdAt: createdAtMillis == null
          ? DateTime.fromMillisecondsSinceEpoch(0)
          : DateTime.fromMillisecondsSinceEpoch(
              createdAtMillis is int
                  ? createdAtMillis
                  : int.parse(createdAtMillis.toString()),
            ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'conversation_id': conversationId,
      'body': body,
      'outgoing': outgoing ? 1 : 0,
      'status': status,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }
}
