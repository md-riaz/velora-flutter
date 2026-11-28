import 'dart:async';

/// A structured diagnostic event recorded by the desktop readiness app.
///
/// All sensitive metadata keys and secret/user-content patterns in [message]
/// are redacted before storage.
final class ReadinessDiagnosticEntry {
  final DateTime timestamp;
  final String category;
  final String message;
  final Map<String, Object?> metadata;

  const ReadinessDiagnosticEntry({
    required this.timestamp,
    required this.category,
    required this.message,
    this.metadata = const {},
  });

  Map<String, Object?> toMap() => {
    'timestamp': timestamp.toIso8601String(),
    'category': category,
    'message': message,
    'metadata': metadata,
  };

  @override
  String toString() =>
      '[${timestamp.toIso8601String()}] [$category] $message'
      '${metadata.isEmpty ? '' : ' $metadata'}';
}

/// Append-only in-memory diagnostics log with automatic secret and user-content
/// redaction.
class ReadinessDiagnosticsLog {
  static const String redactedValue = '[REDACTED]';

  static const Set<String> _sensitiveKeys = {
    'token',
    'authorization',
    'secret',
    'password',
    'bearer',
    'payload',
    'content',
    'body',
    'title',
  };

  static final RegExp _bearerPattern = RegExp(
    r'Bearer\s+[A-Za-z0-9\-._~+/]+=*',
    caseSensitive: false,
  );

  static final RegExp _keyValueSecretPattern = RegExp(
    r'\b(token|authorization|secret|password|bearer|payload|content|body|title)\s*[:=]\s*("[^"]*"|'
    r"'[^']*'|"
    r'\S+)',
    caseSensitive: false,
  );

  static final RegExp _jwtPattern = RegExp(
    r'\beyJ[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\b',
  );

  final int maxEntries;
  final DateTime Function() _now;
  final List<ReadinessDiagnosticEntry> _entries = [];
  final StreamController<List<ReadinessDiagnosticEntry>> _controller =
      StreamController<List<ReadinessDiagnosticEntry>>.broadcast();

  ReadinessDiagnosticsLog({this.maxEntries = 200, DateTime Function()? now})
    : _now = now ?? DateTime.now;

  /// Unmodifiable snapshot of recorded entries in chronological order.
  List<ReadinessDiagnosticEntry> get entries => List.unmodifiable(_entries);

  /// Emits the updated entry list whenever a new entry is recorded or cleared.
  Stream<List<ReadinessDiagnosticEntry>> get stream => _controller.stream;

  /// Records a diagnostic event after redacting [message] and [metadata].
  ReadinessDiagnosticEntry record(
    String category,
    String message, {
    Map<String, Object?> metadata = const {},
  }) {
    final entry = ReadinessDiagnosticEntry(
      timestamp: _now(),
      category: category,
      message: redactMessage(message),
      metadata: redactMetadata(metadata),
    );
    _entries.add(entry);
    if (_entries.length > maxEntries) {
      _entries.removeRange(0, _entries.length - maxEntries);
    }
    if (!_controller.isClosed) {
      _controller.add(entries);
    }
    return entry;
  }

  /// Clears all recorded entries.
  void clear() {
    _entries.clear();
    if (!_controller.isClosed) {
      _controller.add(const []);
    }
  }

  /// Disposes the internal stream controller.
  Future<void> dispose() async {
    await _controller.close();
  }

  /// Redacts bearer tokens, JWTs, and sensitive key/value pairs in [input].
  static String redactMessage(String input) {
    var result = input.replaceAll(_bearerPattern, 'Bearer $redactedValue');
    result = result.replaceAll(_jwtPattern, redactedValue);
    result = result.replaceAllMapped(
      _keyValueSecretPattern,
      (match) => '${match.group(1)}=$redactedValue',
    );
    return result;
  }

  /// Recursively redacts any sensitive key in [metadata].
  static Map<String, Object?> redactMetadata(Map<String, Object?> metadata) {
    if (metadata.isEmpty) return const {};
    final out = <String, Object?>{};
    for (final entry in metadata.entries) {
      if (_isSensitiveKey(entry.key)) {
        out[entry.key] = redactedValue;
      } else {
        out[entry.key] = _redactValue(entry.value);
      }
    }
    return Map<String, Object?>.unmodifiable(out);
  }

  static bool _isSensitiveKey(String key) {
    final lower = key.toLowerCase();
    for (final sensitive in _sensitiveKeys) {
      if (lower.contains(sensitive)) return true;
    }
    return false;
  }

  static Object? _redactValue(Object? value) {
    if (value is Map<String, Object?>) {
      return redactMetadata(value);
    }
    if (value is Map) {
      return redactMetadata(value.map((k, v) => MapEntry(k.toString(), v)));
    }
    if (value is List) {
      return List<Object?>.unmodifiable(value.map(_redactValue));
    }
    if (value is String) {
      return redactMessage(value);
    }
    return value;
  }
}
