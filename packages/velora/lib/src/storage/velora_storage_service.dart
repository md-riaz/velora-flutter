import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class VeloraStorageService extends GetxService {
  static const _defaultTokenKey = 'velora.auth.token';
  final String _tokenKey;
  late final SharedPreferences _prefs;
  final FlutterSecureStorage _secureStorage;

  VeloraStorageService({
    FlutterSecureStorage? secureStorage,
    String tokenKey = 'velora.auth.token',
  })  : _secureStorage = secureStorage ?? const FlutterSecureStorage(),
        _tokenKey = tokenKey;

  Future<VeloraStorageService> init() async {
    _prefs = await SharedPreferences.getInstance();
    return this;
  }

  Future<void> set(String key, Object value) async {
    switch (value) {
      case String():
        await _prefs.setString(key, value);
      case int():
        await _prefs.setInt(key, value);
      case double():
        await _prefs.setDouble(key, value);
      case bool():
        await _prefs.setBool(key, value);
      case List<String>():
        await _prefs.setStringList(key, value);
      default:
        await setJson(key, value);
    }
  }

  T? get<T>(String key) => _prefs.get(key) as T?;

  Future<void> remove(String key) => _prefs.remove(key);

  Future<void> clear() => _prefs.clear();

  Future<void> setJson(String key, Object? value) {
    return _prefs.setString(key, jsonEncode(value));
  }

  Map<String, dynamic>? getJson(String key) {
    final value = _prefs.getString(key);
    if (value == null) return null;
    try {
      final decoded = jsonDecode(value);
      return decoded is Map<String, dynamic> ? decoded : null;
    } on FormatException {
      return null;
    }
  }

  Future<void> setToken(String token) async {
    try {
      await _secureStorage.write(key: _tokenKey, value: token);
    } catch (_) {
      await _prefs.setString(_tokenKey, token);
    }
  }

  Future<String?> getToken() async {
    try {
      var token = await _secureStorage.read(key: _tokenKey) ??
          _prefs.getString(_tokenKey);
      if (token != null) return token;
      // Migrate legacy default key when a custom key is in use.
      if (_tokenKey == _defaultTokenKey) return null;
      token = await _secureStorage.read(key: _defaultTokenKey) ??
          _prefs.getString(_defaultTokenKey);
      if (token == null) return null;
      await setToken(token);
      await _secureStorage.delete(key: _defaultTokenKey);
      await _prefs.remove(_defaultTokenKey);
      return token;
    } catch (_) {
      return _prefs.getString(_tokenKey);
    }
  }

  Future<void> clearToken() async {
    try {
      await _secureStorage.delete(key: _tokenKey);
      if (_tokenKey != _defaultTokenKey) {
        await _secureStorage.delete(key: _defaultTokenKey);
      }
    } catch (_) {
      // Shared preferences fallback below still clears token.
    }
    await _prefs.remove(_tokenKey);
    if (_tokenKey != _defaultTokenKey) {
      await _prefs.remove(_defaultTokenKey);
    }
  }
}
