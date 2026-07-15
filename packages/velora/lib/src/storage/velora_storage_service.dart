import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists app data ([SharedPreferences]) and the auth token
/// ([FlutterSecureStorage]).
///
/// ## Token storage security
///
/// The bearer token is written to the platform secure enclave
/// (Keychain / Keystore). By default the service **never** silently downgrades
/// to unencrypted [SharedPreferences]: if secure storage is unavailable the
/// error propagates so a misconfiguration surfaces instead of leaking the token
/// to disk in cleartext.
///
/// Set [allowInsecureFallback] to `true` only if you knowingly accept plaintext
/// token storage on devices where the secure enclave is unavailable (e.g. some
/// rooted emulators). It is off by default.
class VeloraStorageService extends GetxService {
  static const _defaultTokenKey = 'velora.auth.token';

  final String _tokenKey;
  late final SharedPreferences _prefs;
  final FlutterSecureStorage _secureStorage;

  /// When `true`, the token is written to / read from plaintext
  /// [SharedPreferences] if the secure enclave throws. Off by default.
  final bool allowInsecureFallback;

  VeloraStorageService({
    FlutterSecureStorage? secureStorage,
    String tokenKey = _defaultTokenKey,
    this.allowInsecureFallback = false,
  })  : _secureStorage = secureStorage ?? _defaultSecureStorage,
        _tokenKey = tokenKey;

  /// Hardened platform defaults: keys are AES-GCM encrypted on Android
  /// (the v10 default) and, on Apple platforms, are marked
  /// `unlocked_this_device` so they are excluded from iCloud/device backups and
  /// never migrate to another device.
  static const _defaultSecureStorage = FlutterSecureStorage(
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.unlocked_this_device,
    ),
    mOptions: MacOsOptions(
      accessibility: KeychainAccessibility.unlocked_this_device,
    ),
  );

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
      // Purge any stale plaintext copy left by a previous insecure fallback.
      await _prefs.remove(_tokenKey);
    } catch (error, stackTrace) {
      if (!allowInsecureFallback) {
        _warnSecureStorageUnavailable('write', error, stackTrace);
        rethrow;
      }
      await _prefs.setString(_tokenKey, token);
    }
  }

  Future<String?> getToken() async {
    final token = await _readTokenForKey(_tokenKey);
    if (token != null) return token;

    // Migrate a token stored under the legacy default key to the custom key.
    if (_tokenKey == _defaultTokenKey) return null;
    final legacy = await _readTokenForKey(_defaultTokenKey);
    if (legacy == null) return null;
    await setToken(legacy);
    await _deleteTokenForKey(_defaultTokenKey);
    return legacy;
  }

  Future<void> clearToken() async {
    await _deleteTokenForKey(_tokenKey);
    if (_tokenKey != _defaultTokenKey) {
      await _deleteTokenForKey(_defaultTokenKey);
    }
  }

  Future<String?> _readTokenForKey(String key) async {
    try {
      final secure = await _secureStorage.read(key: key);
      if (secure != null) return secure;
    } catch (error, stackTrace) {
      if (!allowInsecureFallback) {
        _warnSecureStorageUnavailable('read', error, stackTrace);
        rethrow;
      }
    }
    return allowInsecureFallback ? _prefs.getString(key) : null;
  }

  Future<void> _deleteTokenForKey(String key) async {
    try {
      await _secureStorage.delete(key: key);
    } catch (_) {
      // Secure enclave unavailable — the plaintext removal below still runs so
      // any fallback copy is cleared regardless.
    }
    await _prefs.remove(key);
  }

  void _warnSecureStorageUnavailable(
    String op,
    Object error,
    StackTrace stackTrace,
  ) {
    if (!kDebugMode) return;
    debugPrint(
      'VeloraStorageService: secure storage $op failed and '
      'allowInsecureFallback is false, so the token was not stored in '
      'plaintext. Error: $error',
    );
  }
}
