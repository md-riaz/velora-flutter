import 'dart:async';

import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';
import 'package:velora/velora.dart' hide Response;

import '../data/chat_tables.dart';
import '../data/message.dart';

/// Stands in for a real backend receiving the app's queued message writes.
///
/// In a real app, `velora_offline`'s write outbox only *delivers* the
/// request — the server would persist it, and the app's own sync mechanism
/// (a poll or a websocket) would write the acknowledged/updated row back
/// into `velora_db`. `VeloraOfflineFirstRepository` never pulls data down on
/// its own; reconciling what the server did with a write is the app's job
/// (see that class's dartdoc). This interceptor plays both halves of that
/// round-trip for the demo, purely by writing into `velora_db`: it
/// acknowledges the message (flips it from `'pending'` to `'sent'`) and,
/// periodically, simulates the other side of the conversation replying — so
/// every reactive `watch*` stream in the app updates exactly as it would
/// from a real server exchange, without an actual backend.
class MockChatServerInterceptor extends VeloraApiInterceptor {
  static const _uuid = Uuid();
  static const _replies = [
    'Got it, thanks!',
    'Sounds good 👍',
    'On my way.',
  ];

  int _outgoingCount = 0;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final isMessageWrite = options.path.contains('messages') &&
        options.method.toUpperCase() == 'POST';
    if (!isMessageWrite) {
      handler.next(options);
      return;
    }

    // Resolve immediately isn't right either -- the interceptor's job is to
    // simulate a real network round-trip, so the ack (and any reply) happen
    // on a short delay, then resolve. The delay is what keeps a message
    // visibly 'pending' for a moment in the UI.
    unawaited(_acknowledge(options, handler));
  }

  Future<void> _acknowledge(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final data = options.data;
    await Future<void>.delayed(const Duration(milliseconds: 400));

    try {
      if (data is Map) {
        final id = data['id']?.toString();
        final conversationId = data['conversation_id']?.toString();
        if (id != null && id.isNotEmpty) {
          await messagesTable().update(id, {'status': 'sent'});
          _outgoingCount++;
          // Every 3rd outgoing message gets a simulated reply, to show
          // server -> local push flowing back into the reactive UI without
          // relying on nondeterministic randomness.
          if (_outgoingCount % 3 == 0 && conversationId != null) {
            // Guarded so a failure here can't escape as an unhandled async
            // error -- the Dio handler above has already been (or is about
            // to be) completed independently of this fire-and-forget reply.
            unawaited(
              _simulateIncomingReply(conversationId).catchError((_) {}),
            );
          }
        }
      }
    } catch (e) {
      // The Dio handler must be completed exactly once. If persisting the
      // ack failed, reject instead of resolving so the outbox sees the
      // write as failed rather than silently hanging.
      handler.reject(DioException(requestOptions: options, error: e));
      return;
    }

    handler.resolve(
      Response<Map<String, dynamic>>(
        requestOptions: options,
        statusCode: 200,
        data: const {'ok': true},
      ),
    );
  }

  Future<void> _simulateIncomingReply(String conversationId) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    final reply = Message(
      id: _uuid.v4(),
      conversationId: conversationId,
      body: _replies[(_outgoingCount ~/ 3 - 1) % _replies.length],
      outgoing: false,
      status: 'sent',
      createdAt: DateTime.now(),
    );
    await messagesTable().insert(reply.toMap());
    await conversationsTable().update(conversationId, {
      'last_message': reply.body,
      'last_at': reply.createdAt.millisecondsSinceEpoch,
    });
  }
}
