/// Desktop lifecycle for Velora apps: close-to-tray, single instance, protocol
/// activation, auto-start, and suspend/resume as one event stream.
library;

export 'src/adapters/auto_start_adapter.dart';
export 'src/adapters/link_adapter.dart';
export 'src/adapters/power_adapter.dart';
export 'src/adapters/single_instance_adapter.dart';
export 'src/adapters/tray_adapter.dart';
export 'src/adapters/window_adapter.dart';
export 'src/desktop_coordinator.dart';
export 'src/desktop_event.dart';
export 'src/desktop_ports.dart';
export 'src/desktop_service.dart';
