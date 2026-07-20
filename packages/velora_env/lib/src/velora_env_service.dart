import 'package:get/get.dart';

import 'velora_env.dart';
import 'velora_environment.dart';

/// A thin `GetxService` wrapper around [VeloraEnv], for apps that want the
/// resolved environment available through DI/introspection (e.g.
/// `Get.find<VeloraEnvService>()` from a widget test, or another plugin that
/// only knows how to reach dependencies through [VeloraContext]).
///
/// This is **not** the primary way to read config — [VeloraEnv]'s static
/// members work everywhere, including before `Velora.boot()` runs, and don't
/// require this service to be registered at all. Reach for
/// [VeloraEnvService] only when a piece of code specifically needs its
/// environment/config lookups injected rather than reading `VeloraEnv`
/// directly.
class VeloraEnvService extends GetxService {
  /// The environment this service was resolved for. Set once at
  /// registration time (see [VeloraEnvPlugin]); does not change afterward.
  final VeloraEnvironment environment;

  VeloraEnvService({required this.environment});

  /// Reads a raw value, exactly like [VeloraEnv.get].
  String? get(String key, {String? fallback}) =>
      VeloraEnv.get(key, fallback: fallback);

  /// Reads a required value, exactly like [VeloraEnv.require].
  String require(String key) => VeloraEnv.require(key);

  /// Whether [key] is present, exactly like [VeloraEnv.has].
  bool has(String key) => VeloraEnv.has(key);

  /// All currently loaded key/value pairs (unmodifiable), exactly like
  /// [VeloraEnv.all].
  Map<String, String> get all => VeloraEnv.all;
}
