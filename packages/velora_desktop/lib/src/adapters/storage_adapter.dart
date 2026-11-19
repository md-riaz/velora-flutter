import 'package:shared_preferences/shared_preferences.dart';

import '../desktop_ports.dart';

/// [VeloraDesktopStoragePort] over [SharedPreferences].
class SharedPreferencesStorageAdapter implements VeloraDesktopStoragePort {
  SharedPreferencesStorageAdapter(this._prefs);

  final SharedPreferences _prefs;

  @override
  Future<String?> get(String key) async => _prefs.getString(key);

  @override
  Future<void> set(String key, String value) async {
    await _prefs.setString(key, value);
  }
}
