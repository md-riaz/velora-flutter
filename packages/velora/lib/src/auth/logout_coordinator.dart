import 'package:get/get.dart';

import '../core/velora_facade.dart';
import '../core/velora_lifecycle.dart';
import '../routing/velora_nav.dart';
import 'session_state.dart';

class LogoutCoordinator extends GetxService {
  final VeloraLifecycleRegistry lifecycle;
  Future<void>? _running;

  LogoutCoordinator({required this.lifecycle});

  final RxBool isRunning = false.obs;

  Future<void> run({
    required Future<void> Function() remoteLogout,
    required Future<void> Function() clearSession,
  }) {
    final inFlight = _running;
    if (inFlight != null) return inFlight;

    final logout = _run(remoteLogout: remoteLogout, clearSession: clearSession);
    _running = logout;
    return logout.whenComplete(() {
      _running = null;
    });
  }

  Future<void> _run({
    required Future<void> Function() remoteLogout,
    required Future<void> Function() clearSession,
  }) async {
    isRunning.value = true;
    Velora.auth.state.value = SessionState.loggingOut;

    try {
      await lifecycle.beforeLogout();

      try {
        await remoteLogout();
      } catch (_) {
        // Local logout is security-critical and must continue offline.
      }

      await _navigateToGuestRoute();
      await _nextFrame();
      await lifecycle.afterLogoutNavigation();
      await clearSession();
      await lifecycle.onLogoutDispose();
    } finally {
      Velora.auth.state.value = SessionState.guest;
      isRunning.value = false;
    }
  }

  Future<void> _navigateToGuestRoute() async {
    if (!Get.isRegistered<VeloraNav>()) return;

    try {
      await Velora.nav.offAll<void>(Velora.config.auth.logoutRedirectRoute);
    } catch (_) {
      // Navigation is best-effort in tests and headless runtimes.
    }
  }

  Future<void> _nextFrame() async {
    await Future<void>.delayed(Duration.zero);
  }
}
