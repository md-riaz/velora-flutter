import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;
import 'package:flutter/services.dart' show AssetBundle;
import 'package:velora/velora.dart';

import 'velora_env.dart';
import 'velora_env_service.dart';
import 'velora_environment.dart';

/// An official Velora plugin that wires [VeloraEnv] into the DI container
/// as a [VeloraEnvService], for code that needs environment/config lookups
/// injected rather than reaching for the static facade.
///
/// ```dart
/// await Velora.boot(
///   config: myConfig,
///   plugins: [VeloraEnvPlugin()],
/// );
/// ```
///
/// ## `VeloraEnv` is the primary API
///
/// In most apps you won't need this plugin at all: [VeloraEnv.load] can (and
/// usually should) run directly in `main()`, *before* `Velora.boot()`, so its
/// values are available to build `VeloraConfig` itself (e.g.
/// `apiBaseUrl: VeloraEnv.require('API_BASE_URL')`). This plugin exists for
/// the narrower case of DI/introspection — e.g. resolving
/// `Get.find<VeloraEnvService>()` in a widget test, or handing environment
/// data to another plugin through [VeloraContext] instead of a direct static
/// reach.
class VeloraEnvPlugin extends VeloraPlugin {
  /// Passed through to [VeloraEnv.load] when [loadIfNeeded] triggers a load.
  final String? asset;

  /// Passed through to [VeloraEnv.load] when [loadIfNeeded] triggers a load.
  final VeloraEnvironment? environment;

  /// Passed through to [VeloraEnv.load] when [loadIfNeeded] triggers a load.
  /// Defaults to `rootBundle` (via [VeloraEnv.load]'s own default). Mainly
  /// useful for injecting a fake bundle in tests.
  final AssetBundle? bundle;

  /// When true (the default), [register] calls [VeloraEnv.load] if
  /// [VeloraEnv.isLoaded] is still false — i.e. if nothing loaded it earlier
  /// in `main()`. Set to false if your app always loads explicitly before
  /// `Velora.boot()` and wants the plugin to be a pure DI registration.
  final bool loadIfNeeded;

  VeloraEnvPlugin({
    this.asset,
    this.environment,
    this.bundle,
    this.loadIfNeeded = true,
  });

  @override
  String get name => 'velora_env';

  @override
  Future<void> register(VeloraContext context) async {
    if (loadIfNeeded && !VeloraEnv.isLoaded) {
      try {
        await VeloraEnv.load(
          asset: asset,
          environment: environment,
          bundle: bundle,
        );
      } catch (error) {
        // Don't crash app boot over missing/misconfigured .env assets --
        // config that depends on a key the developer forgot to bundle will
        // surface loudly at the call site instead (VeloraEnv.require
        // throws a clear StateError).
        if (kDebugMode) {
          debugPrint('VeloraEnvPlugin: failed to load .env assets: $error');
        }
      }
    }

    context.put<VeloraEnvService>(
      VeloraEnvService(environment: environment ?? VeloraEnv.current),
    );
  }
}
