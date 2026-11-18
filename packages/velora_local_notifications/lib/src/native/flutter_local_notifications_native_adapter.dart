import 'dart:async';
import 'dart:convert';

import '../local_notifications_client.dart';
import '../flutter_local_notifications_client.dart';
import 'native_notification_models.dart';
import 'velora_native_notifications.dart';

/// [VeloraNativeNotifications] backed by `flutter_local_notifications`.
///
/// Maps Velora's string IDs to the plugin's int IDs via stable FNV-1a hashing,
/// translates [VeloraNativeAction] to platform action descriptors, and merges
/// cold-start and live activations into one [activations] stream.
class FlutterLocalNotificationsNativeAdapter
    implements VeloraNativeNotifications {
  FlutterLocalNotificationsNativeAdapter({LocalNotificationsClient? client})
    : _client = client ?? FlutterLocalNotificationsClient();

  final LocalNotificationsClient _client;

  final StreamController<VeloraNotificationActivation> _activations =
      StreamController<VeloraNotificationActivation>.broadcast();

  /// Reverse map: int hash → string ID, so activations can report the
  /// original string ID rather than the hashed int.
  final Map<int, String> _idMap = {};

  /// Tracks recently delivered activation IDs for deduplication (cold-start
  /// + live can fire the same activation twice on some platforms).
  final Map<String, DateTime> _recentActivations = {};

  static const _deduplicationWindow = Duration(seconds: 2);

  bool _disposed = false;

  @override
  Stream<VeloraNotificationActivation> get activations => _activations.stream;

  @override
  Future<void> initialize() async {
    await _client.initialize(
      onActivation: _handleActivation,
    );
  }

  @override
  Future<void> show(VeloraNativeNotification notification) async {
    final intId = _hashId(notification.id);
    _idMap[intId] = notification.id;

    final actions = notification.actions.map((a) => {
      'id': a.id,
      'label': a.label,
      'textInputPlaceholder': a.textInputPlaceholder,
    }).toList();

    final payload = <String, dynamic>{
      'veloraId': notification.id,
      ...notification.payload,
    };

    await _client.show(
      intId,
      notification.title,
      notification.body,
      payload: jsonEncode(payload),
      actions: actions,
      silent: notification.silent,
    );
  }

  @override
  Future<void> cancel(String id) => _client.cancel(_hashId(id));

  @override
  Future<void> cancelAll() async {
    _idMap.clear();
    await _client.cancelAll();
  }

  @override
  Future<void> dispose() async {
    _disposed = true;
    _idMap.clear();
    _recentActivations.clear();
    await _activations.close();
  }

  void _handleActivation({
    required int id,
    String? actionId,
    String? input,
    String? payload,
    Map<String, dynamic> data = const {},
  }) {
    if (_disposed) return;

    // Recover the original string ID. First try the payload (survives app
    // restart), then the in-memory reverse map.
    String stringId;
    Map<String, dynamic> payloadMap = const {};
    if (payload != null && payload.isNotEmpty) {
      try {
        final decoded = jsonDecode(payload) as Map<String, dynamic>;
        stringId = (decoded.remove('veloraId') as String?) ??
            (_idMap[id] ?? id.toString());
        payloadMap = decoded;
      } on Object {
        stringId = _idMap[id] ?? id.toString();
      }
    } else {
      stringId = _idMap[id] ?? id.toString();
    }

    // Deduplicate within the window.
    final dedupKey = '$stringId:${actionId ?? ''}';
    final now = DateTime.now();
    final lastSeen = _recentActivations[dedupKey];
    if (lastSeen != null && now.difference(lastSeen) < _deduplicationWindow) {
      return;
    }
    _recentActivations[dedupKey] = now;

    // Prune old entries.
    _recentActivations.removeWhere(
      (_, ts) => now.difference(ts) > _deduplicationWindow,
    );

    _activations.add(VeloraNotificationActivation(
      id: stringId,
      actionId: actionId,
      input: input,
      payload: payloadMap,
      data: data,
    ));
  }

  /// Deterministically hashes [id] to a positive 32-bit int using FNV-1a.
  static int _hashId(String id) {
    var hash = 0x811c9dc5;
    for (final codeUnit in id.codeUnits) {
      hash ^= codeUnit;
      hash = (hash * 0x01000193) & 0xFFFFFFFF;
    }
    return hash & 0x7FFFFFFF;
  }
}
