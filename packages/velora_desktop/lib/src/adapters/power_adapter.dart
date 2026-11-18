import 'dart:async';

import 'package:power_state_monitor/power_state_monitor.dart' as psm;

import '../desktop_ports.dart';

/// [VeloraDesktopPowerPort] over `power_state_monitor`.
class PowerStateMonitorAdapter implements VeloraDesktopPowerPort {
  PowerStateMonitorAdapter();

  final StreamController<VeloraPowerSignal> _controller =
      StreamController<VeloraPowerSignal>.broadcast();
  StreamSubscription<psm.PowerStateEvent>? _subscription;

  @override
  Future<bool> start() async {
    try {
      final ok = await psm.PowerStateMonitor.instance.initialize();
      if (!ok) return false;
      _subscription =
          psm.PowerStateMonitor.instance.onPowerStateChanged.listen((event) {
        switch (event) {
          case psm.PowerStateEvent.suspend:
            _controller.add(VeloraPowerSignal.suspending);
          case psm.PowerStateEvent.resumeSuspend:
          case psm.PowerStateEvent.resumeAutomatic:
            _controller.add(VeloraPowerSignal.resumed);
        }
      });
      return true;
    } on Object {
      return false;
    }
  }

  @override
  Stream<VeloraPowerSignal> get signals => _controller.stream;

  @override
  Future<void> stop() async {
    await _subscription?.cancel();
    _subscription = null;
    psm.PowerStateMonitor.instance.dispose();
    await _controller.close();
  }
}
