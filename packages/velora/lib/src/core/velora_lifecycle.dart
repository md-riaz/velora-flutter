import 'package:get/get.dart';

abstract interface class VeloraLogoutAware {
  Future<void> beforeLogout();
  Future<void> afterLogoutNavigation();
  Future<void> onLogoutDispose();
}

mixin VeloraLogoutAwareDefaults implements VeloraLogoutAware {
  @override
  Future<void> beforeLogout() async {}

  @override
  Future<void> afterLogoutNavigation() async {}

  @override
  Future<void> onLogoutDispose() async {}
}

/// A [VeloraLogoutAware] participant built from optional closures, so
/// call-site logic can hook into the logout lifecycle without needing a
/// dedicated service class.
class VeloraLogoutHook implements VeloraLogoutAware {
  final Future<void> Function()? onBeforeLogout;
  final Future<void> Function()? onAfterLogoutNavigation;
  final Future<void> Function()? onLogoutDisposeHook;

  const VeloraLogoutHook({
    this.onBeforeLogout,
    this.onAfterLogoutNavigation,
    this.onLogoutDisposeHook,
  });

  @override
  Future<void> beforeLogout() async {
    await onBeforeLogout?.call();
  }

  @override
  Future<void> afterLogoutNavigation() async {
    await onAfterLogoutNavigation?.call();
  }

  @override
  Future<void> onLogoutDispose() async {
    await onLogoutDisposeHook?.call();
  }
}

class VeloraLifecycleRegistry extends GetxService {
  final List<VeloraLogoutAware> _logoutAware = [];

  void register(VeloraLogoutAware service) {
    if (!_logoutAware.contains(service)) {
      _logoutAware.add(service);
    }
  }

  void unregister(VeloraLogoutAware service) {
    _logoutAware.remove(service);
  }

  Future<void> beforeLogout() => _run((service) => service.beforeLogout());

  Future<void> afterLogoutNavigation() {
    return _run((service) => service.afterLogoutNavigation());
  }

  Future<void> onLogoutDispose() =>
      _run((service) => service.onLogoutDispose());

  Future<void> _run(
    Future<void> Function(VeloraLogoutAware service) hook,
  ) async {
    for (final service in List<VeloraLogoutAware>.from(_logoutAware)) {
      try {
        await hook(service);
      } catch (_) {
        // Logout hooks must not block local session teardown.
      }
    }
  }
}
