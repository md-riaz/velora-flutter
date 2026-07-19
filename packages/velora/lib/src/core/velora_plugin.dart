import 'package:get/get.dart';

import '../config/velora_config.dart';
import '../http/velora_api_interceptor.dart';
import '../http/velora_api_service.dart';
import 'velora_lifecycle.dart';

/// Implement this to package a self-contained Velora extension (an official
/// `velora_*` package or your own). Register it via `Velora.boot(plugins: [...])`;
/// [register] runs after core services are wired, so the plugin can add its own
/// services, HTTP interceptors, and logout hooks.
abstract class VeloraPlugin {
  const VeloraPlugin();

  /// Stable, unique identifier, e.g. 'velora_offline'. Used for introspection.
  String get name;

  /// Wire the plugin's dependencies into the running app.
  Future<void> register(VeloraContext context);
}

/// The surface a [VeloraPlugin] uses to wire itself into the composition root,
/// so plugins never touch GetX or the facade directly.
class VeloraContext {
  final VeloraConfig config;
  const VeloraContext(this.config);

  /// Register a permanent singleton, resolvable elsewhere via Get.find / a facade.
  void put<T>(T dependency) => Get.put<T>(dependency, permanent: true);

  T find<T>() => Get.find<T>();
  bool isRegistered<T>() => Get.isRegistered<T>();

  /// Add an HTTP interceptor to the shared API client (runs after the built-in
  /// auth-token injector, in registration order).
  void addInterceptor(VeloraApiInterceptor interceptor) =>
      find<VeloraApiService>().addInterceptor(interceptor);

  /// Register a logout lifecycle participant.
  void onLogout(VeloraLogoutAware participant) =>
      find<VeloraLifecycleRegistry>().register(participant);

  /// Convenience: run [hook] during the beforeLogout phase.
  void onBeforeLogout(Future<void> Function() hook) =>
      onLogout(VeloraLogoutHook(onBeforeLogout: hook));

  /// Retrieve a typed config extension the app registered on [VeloraConfig].
  T? configExtension<T extends VeloraConfigExtension>() => config.extension<T>();
}
