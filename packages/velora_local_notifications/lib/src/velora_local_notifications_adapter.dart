import 'dart:convert';

import 'package:velora/velora.dart';

import 'flutter_local_notifications_client.dart';
import 'local_notifications_client.dart';

/// A [LocalNotificationAdapter] backed by `flutter_local_notifications`.
///
/// `flutter_local_notifications` requires integer notification ids, but
/// [LocalNotificationAdapter.schedule] and [LocalNotificationAdapter.cancel]
/// deal in `String` ids, and [LocalNotificationAdapter.show] doesn't take an
/// id at all. This adapter bridges that gap with a small, deterministic id
/// registry:
///
/// * A private incrementing counter is the source of every synthesized int
///   id (starting at 1).
/// * For [schedule], a `Map<String, int>` remembers the int id assigned to
///   each caller-supplied string id. Scheduling the *same* string id again
///   reuses its existing int id (so the underlying plugin call overwrites
///   the previous notification instead of leaving a stale duplicate behind)
///   -- it does not consume a new counter value. [cancel] looks the string
///   id up in this map to find the int id to cancel.
/// * [show] has no caller-supplied id to key off of, so it simply draws the
///   next counter value every call; there is nothing to look up later.
///
/// All plugin-specific concerns (notification channels, Darwin settings,
/// timezone conversion, ...) live in [LocalNotificationsClient]
/// implementations, not here -- this class only ever touches plain ints,
/// strings and [DateTime]s, which keeps it trivially testable with a fake
/// client (see `test/velora_local_notifications_test.dart`).
class VeloraLocalNotificationsAdapter implements LocalNotificationAdapter {
  VeloraLocalNotificationsAdapter({LocalNotificationsClient? client})
      : _client = client ?? FlutterLocalNotificationsClient();

  final LocalNotificationsClient _client;

  /// Maps a caller-supplied `schedule`/`cancel` string id to the int id
  /// registered with the underlying client.
  final Map<String, int> _scheduledIds = <String, int>{};

  int _nextId = 1;

  @override
  Future<void> init() => _client.initialize();

  @override
  Future<void> show({
    required String title,
    required String body,
    Map<String, dynamic> payload = const {},
  }) {
    final id = _nextId++;
    return _client.show(
      id,
      title,
      body,
      payload: _encodePayload(payload),
    );
  }

  @override
  Future<void> schedule({
    required String id,
    required String title,
    required String body,
    required DateTime dateTime,
    Map<String, dynamic> payload = const {},
  }) {
    final intId = _scheduledIds.putIfAbsent(id, () => _nextId++);
    return _client.zonedSchedule(
      intId,
      title,
      body,
      dateTime,
      payload: _encodePayload(payload),
    );
  }

  @override
  Future<void> cancel(String id) {
    final intId = _scheduledIds.remove(id);
    if (intId == null) {
      return Future<void>.value();
    }
    return _client.cancel(intId);
  }

  @override
  Future<void> cancelAll() {
    _scheduledIds.clear();
    return _client.cancelAll();
  }

  /// `flutter_local_notifications` carries the payload as a single opaque
  /// `String?`, so a non-empty payload map is serialized to JSON; an empty
  /// map (the default) is passed through as `null` to avoid sending an
  /// empty `'{}'` string with every call.
  String? _encodePayload(Map<String, dynamic> payload) {
    if (payload.isEmpty) return null;
    return jsonEncode(payload);
  }
}
