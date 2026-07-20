import 'package:flutter/services.dart' show AssetBundle, rootBundle;

import 'env_parser.dart';
import 'velora_environment.dart';

/// Laravel-style static environment/config facade.
///
/// `VeloraEnv` is the **primary API** of this package. It's a plain static
/// holder — no GetX, no plugin registration required — so it can be read as
/// early as `main()`, *before* `Velora.boot()` runs, to build the
/// `VeloraConfig` itself:
///
/// ```dart
/// Future<void> main() async {
///   WidgetsFlutterBinding.ensureInitialized();
///   await VeloraEnv.load();
///
///   await Velora.boot(
///     config: VeloraConfig(
///       appName: 'My App',
///       apiBaseUrl: VeloraEnv.require('API_BASE_URL'),
///     ),
///     plugins: [
///       // Optional: only needed for DI/introspection (Get.find<VeloraEnvService>()).
///       VeloraEnvPlugin(),
///     ],
///   );
/// }
/// ```
///
/// ## Not a secret store
///
/// `.env` files loaded through this package are bundled into the app as
/// Flutter assets — they ship inside the APK/IPA and can be extracted by
/// anyone with the installed binary. Use `.env` for **configuration and
/// flavor switching** (API base URLs, feature flags, environment labels),
/// never for secrets (API keys with real privileges, private credentials).
/// Ship real secrets from your backend, a secrets manager, or platform-level
/// secure storage instead.
class VeloraEnv {
  VeloraEnv._();

  static Map<String, String> _values = const {};
  static bool _isLoaded = false;

  /// The current [VeloraEnvironment], resolved from the `VELORA_ENV`
  /// compile-time environment variable (set via
  /// `--dart-define=VELORA_ENV=staging` or `--dart-define-from-file`).
  ///
  /// Defaults to [VeloraEnvironment.dev] when not supplied.
  static VeloraEnvironment get current => VeloraEnvironment.parse(
        const String.fromEnvironment('VELORA_ENV'),
      );

  static bool get isDev => current == VeloraEnvironment.dev;
  static bool get isStaging => current == VeloraEnvironment.staging;
  static bool get isProd => current == VeloraEnvironment.prod;

  /// Whether [load], [loadFromString], or [loadFromMap] has populated any
  /// values yet.
  static bool get isLoaded => _isLoaded;

  /// Loads `.env` values from Flutter assets.
  ///
  /// Asset resolution, when [asset] is omitted, follows a base + flavor
  /// convention:
  /// 1. `assets/env/.env` — the shared base file, loaded first (if present).
  /// 2. `assets/env/.env.<flavor>` — an environment-specific override, where
  ///    `<flavor>` is `(environment ?? current).name` (`dev`, `staging`, or
  ///    `prod`). Its keys are merged over the base file's, overriding
  ///    duplicates.
  ///
  /// A missing flavor asset is tolerated (it's normal for a project to not
  /// define an override for every flavor); the base file is also tolerated
  /// if absent. If neither file exists, [load] completes with no values
  /// loaded rather than throwing.
  ///
  /// When [asset] is supplied explicitly, only that single asset is loaded,
  /// exactly as given — no base/flavor resolution — and a missing asset's
  /// error is allowed to surface (the caller asked for a specific file, so a
  /// silent no-op would hide a real misconfiguration).
  ///
  /// By default, a successful load **replaces** any previously loaded
  /// values. Pass [merge] to instead merge the newly loaded keys over the
  /// existing ones.
  static Future<void> load({
    String? asset,
    VeloraEnvironment? environment,
    AssetBundle? bundle,
    bool merge = false,
  }) async {
    final effectiveBundle = bundle ?? rootBundle;
    final merged = <String, String>{};

    if (asset != null) {
      final content = await effectiveBundle.loadString(asset);
      merged.addAll(parseEnv(content));
    } else {
      final flavor = (environment ?? current).name;

      try {
        final base = await effectiveBundle.loadString('assets/env/.env');
        merged.addAll(parseEnv(base));
      } catch (_) {
        // No shared base file — that's fine.
      }

      try {
        final flavorContent = await effectiveBundle.loadString(
          'assets/env/.env.$flavor',
        );
        merged.addAll(parseEnv(flavorContent));
      } catch (_) {
        // No flavor-specific override — that's fine too.
      }
    }

    _values = merge ? {..._values, ...merged} : merged;
    _isLoaded = true;
  }

  /// Synchronously loads `.env` values from an in-memory string. Intended
  /// for tests (and any caller that already has the file contents, e.g.
  /// read via `dart:io` outside of Flutter assets).
  ///
  /// [environment] is accepted for symmetry with [load] but doesn't affect
  /// parsing — it exists so callers can express intent ("this is the
  /// staging config") without it changing behavior.
  static void loadFromString(
    String content, {
    VeloraEnvironment? environment,
    bool merge = false,
  }) {
    final parsed = parseEnv(content);
    _values = merge ? {..._values, ...parsed} : parsed;
    _isLoaded = true;
  }

  /// Loads `.env` values directly from a pre-built map. Useful for tests
  /// and for programmatic overrides.
  static void loadFromMap(Map<String, String> values, {bool merge = false}) {
    _values = merge ? {..._values, ...values} : Map.of(values);
    _isLoaded = true;
  }

  /// Returns the raw string value for [key], or [fallback] if absent.
  static String? get(String key, {String? fallback}) {
    return _values[key] ?? fallback;
  }

  /// Returns the raw string value for [key], throwing a [StateError] if the
  /// key is absent or its value is empty.
  static String require(String key) {
    final value = _values[key];
    if (value == null || value.isEmpty) {
      throw StateError('Missing required environment key: "$key"');
    }
    return value;
  }

  /// Whether [key] is present (and has a non-empty value).
  static bool has(String key) {
    final value = _values[key];
    return value != null && value.isNotEmpty;
  }

  /// Parses [key] as a boolean. `true`, `1`, `yes`, and `on` (case
  /// insensitive) are truthy; anything else — including an absent key — is
  /// falsy, unless [fallback] is supplied for the absent case.
  static bool getBool(String key, {bool fallback = false}) {
    final value = _values[key];
    if (value == null) return fallback;
    switch (value.trim().toLowerCase()) {
      case 'true':
      case '1':
      case 'yes':
      case 'on':
        return true;
      default:
        return false;
    }
  }

  /// Parses [key] as an [int], or returns [fallback] if absent/unparsable.
  static int? getInt(String key, {int? fallback}) {
    final value = _values[key];
    if (value == null) return fallback;
    return int.tryParse(value.trim()) ?? fallback;
  }

  /// Parses [key] as a [double], or returns [fallback] if absent/unparsable.
  static double? getDouble(String key, {double? fallback}) {
    final value = _values[key];
    if (value == null) return fallback;
    return double.tryParse(value.trim()) ?? fallback;
  }

  /// All currently loaded key/value pairs, as an unmodifiable map.
  static Map<String, String> get all => Map.unmodifiable(_values);

  /// Picks a value based on [env], falling back to [dev] when [staging] or
  /// [prod] is requested but not supplied.
  static T pickFor<T>(
    VeloraEnvironment env, {
    required T dev,
    T? staging,
    T? prod,
  }) {
    switch (env) {
      case VeloraEnvironment.dev:
        return dev;
      case VeloraEnvironment.staging:
        return staging ?? dev;
      case VeloraEnvironment.prod:
        return prod ?? dev;
    }
  }

  /// Shorthand for `pickFor(current, ...)`.
  static T pick<T>({required T dev, T? staging, T? prod}) {
    return pickFor<T>(current, dev: dev, staging: staging, prod: prod);
  }

  /// Clears all loaded values and resets [isLoaded] to false. Intended for
  /// tests, to avoid state leaking between test cases.
  static void reset() {
    _values = const {};
    _isLoaded = false;
  }
}
