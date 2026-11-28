/// Synchronization status of a [WorkItem].
enum SyncStatus {
  synced,
  pending,
  synchronizing,
  conflict,
  permanentFailure;

  static SyncStatus fromName(String? value) {
    for (final status in SyncStatus.values) {
      if (status.name == value) return status;
    }
    return SyncStatus.synced;
  }
}

/// Domain model for a work item tracked offline-first and reconciled with
/// realtime/remote updates.
class WorkItem {
  final String id;
  final String title;
  final int priority;
  final int version;
  final SyncStatus syncStatus;
  final String? idempotencyKey;
  final String? serverTitle;
  final String? lastError;
  final DateTime updatedAt;

  const WorkItem({
    required this.id,
    required this.title,
    required this.priority,
    required this.version,
    required this.syncStatus,
    this.idempotencyKey,
    this.serverTitle,
    this.lastError,
    required this.updatedAt,
  });

  WorkItem copyWith({
    String? id,
    String? title,
    int? priority,
    int? version,
    SyncStatus? syncStatus,
    String? idempotencyKey,
    bool clearIdempotencyKey = false,
    String? serverTitle,
    bool clearServerTitle = false,
    String? lastError,
    bool clearLastError = false,
    DateTime? updatedAt,
  }) {
    return WorkItem(
      id: id ?? this.id,
      title: title ?? this.title,
      priority: priority ?? this.priority,
      version: version ?? this.version,
      syncStatus: syncStatus ?? this.syncStatus,
      idempotencyKey: clearIdempotencyKey
          ? null
          : (idempotencyKey ?? this.idempotencyKey),
      serverTitle: clearServerTitle ? null : (serverTitle ?? this.serverTitle),
      lastError: clearLastError ? null : (lastError ?? this.lastError),
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'priority': priority,
    'version': version,
    'sync_status': syncStatus.name,
    'idempotency_key': idempotencyKey,
    'server_title': serverTitle,
    'last_error': lastError,
    'updated_at': updatedAt.toUtc().toIso8601String(),
  };

  factory WorkItem.fromMap(Map<String, dynamic> map) {
    final rawUpdatedAt = map['updated_at'];
    final DateTime parsedUpdatedAt;
    if (rawUpdatedAt is int) {
      parsedUpdatedAt = DateTime.fromMillisecondsSinceEpoch(
        rawUpdatedAt,
        isUtc: true,
      );
    } else if (rawUpdatedAt is String && rawUpdatedAt.isNotEmpty) {
      parsedUpdatedAt = DateTime.parse(rawUpdatedAt).toUtc();
    } else {
      parsedUpdatedAt = DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
    }

    return WorkItem(
      id: map['id'] as String,
      title: map['title'] as String,
      priority: (map['priority'] as num).toInt(),
      version: (map['version'] as num).toInt(),
      syncStatus: SyncStatus.fromName(map['sync_status'] as String?),
      idempotencyKey: map['idempotency_key'] as String?,
      serverTitle: map['server_title'] as String?,
      lastError: map['last_error'] as String?,
      updatedAt: parsedUpdatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WorkItem &&
        other.id == id &&
        other.title == title &&
        other.priority == priority &&
        other.version == version &&
        other.syncStatus == syncStatus &&
        other.idempotencyKey == idempotencyKey &&
        other.serverTitle == serverTitle &&
        other.lastError == lastError &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    priority,
    version,
    syncStatus,
    idempotencyKey,
    serverTitle,
    lastError,
    updatedAt,
  );
}
