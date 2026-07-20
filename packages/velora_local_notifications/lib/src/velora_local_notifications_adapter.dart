import 'dart:convert';

import 'package:velora/velora.dart';

import 'flutter_local_notifications_client.dart';
import 'local_notifications_client.dart';

/// A [LocalNotificationAdapter] backed by `flutter_local_notifications`.
///
/// `flutter_local_notifications` requires integer notification ids, but
/// [LocalNotificationAdapter.schedule] and [LocalNotificationAdapter.cancel]
/// deal in `String` ids, and [LocalNotificationAdapter.show] doesn't take an
/// id at all. This adapter bridges that gap without any in-memory
/// registry, so it stays correct across app restarts:
///
/// * [schedule] and [cancel] derive the int id from the caller-supplied
///   string id via a stable 32-bit FNV-1a hash ([_hashId]). The same string
///   id always hashes to the same int, in this run and in every future run,
///   so re-scheduling a string id overwrites the previous notification (no
///   stale duplicate) and canceling a string id works even after an app
///   restart -- there is no map that could have been reset to empty.
/// * [show] has no caller-supplied id to key off of and nothing to look up
///   later, so it draws ids from a separate counter seeded from the current
///   time (so it doesn't collide with ids used in a previous session) and
///   wrapping on overflow.
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

  /// Seeds the [show] id counter from the current time so ids drawn in this
  /// session don't collide with ids drawn in a previous session (which the
  /// OS may still remember as "shown").
  int _nextShowId = DateTime.now().millisecondsSinceEpoch % 0x7FFFFFFF;

  /// Returns the next `show` notification id and advances the counter.
  ///
  /// `flutter_local_notifications` ids are plain 32-bit platform ints, so
  /// once the counter would overflow `Int32.maxValue` (2147483647) it wraps
  /// back around to 1 instead of growing past what the platform can
  /// represent.
  int _getAndIncrementShowId() {
    final id = _nextShowId;
    _nextShowId = _nextShowId >= 0x7FFFFFFF ? 1 : _nextShowId + 1;
    return id;
  }

  /// Deterministically hashes [id] to a positive 32-bit int using FNV-1a.
  ///
  /// This is stable across app executions (unlike [String.hashCode], which
  /// Dart does not guarantee is stable across isolates/runs), so the same
  /// string id always maps to the same notification id -- including after
  /// an app restart.
  int _hashId(String id) {
    var hash = 0x811c9dc5;
    for (final codeUnit in id.codeUnits) {
      hash ^= codeUnit;
      hash = (hash * 0x01000193) & 0xFFFFFFFF;
    }
    return hash & 0x7FFFFFFF;
  }

  @override
  Future<void> init() => _client.initialize();

  @override
  Future<void> show({
    required String title,
    required String body,
    Map<String, dynamic> payload = const {},
  }) {
    final id = _getAndIncrementShowId();
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
    final intId = _hashId(id);
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
    return _client.cancel(_hashId(id));
  }

  @override
  Future<void> cancelAll() {
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
