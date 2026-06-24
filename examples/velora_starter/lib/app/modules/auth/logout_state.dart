import 'package:velora/velora.dart';

bool isVeloraLogoutRunning() {
  return _authIsLoggingOut() || _logoutTaskIsRunning();
}

bool _authIsLoggingOut() {
  try {
    return _readBoolFlag(Velora.auth.isLoggingOut);
  } catch (_) {
    return false;
  }
}

bool _logoutTaskIsRunning() {
  try {
    return _readBoolFlag(Velora.logoutCoordinator.isRunning);
  } catch (_) {
    return false;
  }
}

bool _readBoolFlag(Object? flag) {
  if (flag is bool) return flag;
  try {
    final value = (flag as dynamic).value;
    if (value is bool) return value;
  } catch (_) {
    // Support Velora versions where the flag is absent.
  }
  return false;
}
