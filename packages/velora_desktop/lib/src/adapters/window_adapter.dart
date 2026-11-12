import 'package:nativeapi/nativeapi.dart' as nativeapi;

import '../desktop_ports.dart';

/// [VeloraDesktopWindowPort] over nativeapi [nativeapi.Window].
///
/// window_manager 0.6 re-exports [nativeapi.WindowManager] — we go through
/// nativeapi directly so the adapter has no dependency on the legacy surface.
class WindowManagerAdapter implements VeloraDesktopWindowPort {
  WindowManagerAdapter();

  nativeapi.Window? _window;
  bool Function()? _onCloseRequested;
  nativeapi.ListenerId? _listenerId;

  @override
  Future<void> attach({required bool Function() onCloseRequested}) async {
    _onCloseRequested = onCloseRequested;
    _window = nativeapi.WindowManager.instance.getCurrent();
    if (_window == null) return;
    _listenerId = _window!.addListener((event) {
      if (event is nativeapi.WindowCloseRequestedEvent) {
        final mayClose = _onCloseRequested?.call() ?? true;
        if (!mayClose) event.request.cancel();
      }
    });
  }

  @override
  Future<void> show({required bool focus}) async {
    final w = _window;
    if (w == null) return;
    w.show();
    if (focus) w.focus();
  }

  @override
  Future<void> hide() async => _window?.hide();

  @override
  Future<void> close() async => _window?.close();

  @override
  Future<void> detach() async {
    final id = _listenerId;
    if (id != null) _window?.removeListener(id);
    _listenerId = null;
    _onCloseRequested = null;
  }
}
