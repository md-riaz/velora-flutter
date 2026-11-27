import 'dart:convert';

import 'velora_storage_service.dart';

/// Volatile storage for tests; tokens are never written to disk.
class InMemoryStorage extends VeloraStorageService {
  final Map<String, Object> _values = {};
  final Map<String, String> _secureValues = {};
  String? _token;

  @override
  Future<InMemoryStorage> init() async => this;

  @override
  Future<void> set(String key, Object value) async {
    if (value is String || value is int || value is double || value is bool) {
      _values[key] = value;
    } else if (value is List<String>) {
      _values[key] = List<String>.of(value);
    } else {
      await setJson(key, value);
    }
  }

  @override
  T? get<T>(String key) => _values[key] as T?;

  @override
  Future<void> remove(String key) async => _values.remove(key);

  @override
  Future<void> clear() async {
    _values.clear();
    _secureValues.clear();
  }

  @override
  Future<void> setJson(String key, Object? value) async {
    _values[key] = jsonEncode(value);
  }

  @override
  Map<String, dynamic>? getJson(String key) {
    final value = _values[key];
    if (value == null) return null;
    try {
      final decoded = jsonDecode(value as String);
      return decoded is Map<String, dynamic> ? decoded : null;
    } on FormatException {
      return null;
    }
  }

  @override
  Future<void> setSecure(String key, String value) async =>
      _secureValues[key] = value;

  @override
  Future<String?> getSecure(String key) async => _secureValues[key];

  @override
  Future<void> removeSecure(String key) async => _secureValues.remove(key);

  @override
  Future<void> setToken(String token) async => _token = token;

  @override
  Future<String?> getToken() async => _token;

  @override
  Future<void> clearToken() async => _token = null;
}
