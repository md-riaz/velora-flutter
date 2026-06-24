abstract class LocalNotificationAdapter {
  Future<void> init();

  Future<void> show({
    required String title,
    required String body,
    Map<String, dynamic> payload = const {},
  });

  Future<void> schedule({
    required String id,
    required String title,
    required String body,
    required DateTime dateTime,
    Map<String, dynamic> payload = const {},
  });

  Future<void> cancel(String id);

  Future<void> cancelAll();
}

class LocalNotificationRecord {
  final String id;
  final String title;
  final String body;
  final Map<String, dynamic> payload;
  final DateTime? scheduledAt;
  final DateTime createdAt;

  const LocalNotificationRecord({
    required this.id,
    required this.title,
    required this.body,
    this.payload = const {},
    this.scheduledAt,
    required this.createdAt,
  });
}

class InMemoryLocalNotificationAdapter implements LocalNotificationAdapter {
  final List<LocalNotificationRecord> shown = <LocalNotificationRecord>[];
  final Map<String, LocalNotificationRecord> scheduled =
      <String, LocalNotificationRecord>{};
  bool initialized = false;

  @override
  Future<void> init() async {
    initialized = true;
  }

  @override
  Future<void> show({
    required String title,
    required String body,
    Map<String, dynamic> payload = const {},
  }) async {
    shown.add(
      LocalNotificationRecord(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        title: title,
        body: body,
        payload: Map<String, dynamic>.from(payload),
        createdAt: DateTime.now(),
      ),
    );
  }

  @override
  Future<void> schedule({
    required String id,
    required String title,
    required String body,
    required DateTime dateTime,
    Map<String, dynamic> payload = const {},
  }) async {
    scheduled[id] = LocalNotificationRecord(
      id: id,
      title: title,
      body: body,
      payload: Map<String, dynamic>.from(payload),
      scheduledAt: dateTime,
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<void> cancel(String id) async {
    scheduled.remove(id);
  }

  @override
  Future<void> cancelAll() async {
    scheduled.clear();
    shown.clear();
  }
}
