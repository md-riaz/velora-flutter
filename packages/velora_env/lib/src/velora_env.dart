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
  static VeloraEnvironment? _current;

  /// The current [VeloraEnvironment].
  ///
  /// Resolved, on first read, from the `VELORA_ENV` compile-time environment
  /// variable (set via `--dart-define=VELORA_ENV=staging` or
  /// `--dart-define-from-file`), defaulting to [VeloraEnvironment.dev] when
  /// not supplied.
  ///
  /// [load] and [loadFromString] update this to the environment they were
  /// explicitly given, so [pick]/[isDev]/[isStaging]/[isProd] reflect the
  /// loaded config. It can also be set directly (e.g. in tests, to mock the
  /// active environment without a compile-time define).
  static VeloraEnvironment get current => _current ??= VeloraEnvironment.parse(
        const String.fromEnvironment('VELORA_ENV'),
      );

  /// Overrides [current]. Intended for tests (to mock the active
  /// environment) and is also how [load]/[loadFromString] keep [current] in
  /// sync with an explicitly loaded environment.
  static set current(VeloraEnvironment value) => _current = value;

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
  /// 2. A flavor-specific override for `(environment ?? current)`, whose
  ///    keys are merged over the base file's, overriding duplicates. Both a
  ///    short and a long filename are accepted per flavor (the long form is
  ///    recommended, matching the docs):
  ///    - `dev` → `assets/env/.env.dev`, then `assets/env/.env.development`
  ///    - `staging` → `assets/env/.env.staging`, then
  ///      `assets/env/.env.stag`
  ///    - `prod` → `assets/env/.env.prod`, then
  ///      `assets/env/.env.production`
  ///
  ///    Only the *first* candidate that exists is loaded (they're not both
  ///    applied) — this avoids double-applying if a project happens to have
  ///    both files.
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
  ///
  /// If [environment] is supplied, [current] is updated to match, so
  /// [pick]/[isDev]/[isStaging]/[isProd] reflect the environment that was
  /// just loaded.
  static Future<void> load({
    String? asset,
    VeloraEnvironment? environment,
    AssetBundle? bundle,
    bool merge = false,
  }) async {
    final effectiveBundle = bundle ?? rootBundle;
    final merged = <String, String>{};

    if (environment != null) {
      current = environment;
    }

    if (asset != null) {
      final content = await effectiveBundle.loadString(asset);
      merged.addAll(parseEnv(content));
    } else {
      final resolvedEnvironment = environment ?? current;

      try {
        final base = await effectiveBundle.loadString('assets/env/.env');
        merged.addAll(parseEnv(base));
      } catch (_) {
        // No shared base file — that's fine.
      }

      for (final candidate in _flavorAssetCandidates(resolvedEnvironment)) {
        try {
          final flavorContent = await effectiveBundle.loadString(candidate);
          merged.addAll(parseEnv(flavorContent));
          break; // Only the first existing candidate is applied.
        } catch (_) {
          // This candidate doesn't exist — try the next one.
        }
      }
    }

    _values = merge ? {..._values, ...merged} : merged;
    _isLoaded = true;
  }

  /// Candidate `assets/env/.env.*` filenames for [environment], in the
  /// order they should be tried. Only the first one that exists is loaded.
  static List<String> _flavorAssetCandidates(VeloraEnvironment environment) {
    switch (environment) {
      case VeloraEnvironment.dev:
        return const ['assets/env/.env.dev', 'assets/env/.env.development'];
      case VeloraEnvironment.staging:
        return const ['assets/env/.env.staging', 'assets/env/.env.stag'];
      case VeloraEnvironment.prod:
        return const ['assets/env/.env.prod', 'assets/env/.env.production'];
    }
  }

  /// Synchronously loads `.env` values from an in-memory string. Intended
  /// for tests (and any caller that already has the file contents, e.g.
  /// read via `dart:io` outside of Flutter assets).
  ///
  /// [environment], if supplied, doesn't affect parsing, but updates
  /// [current] to match — so callers can express intent ("this is the
  /// staging config") and have [pick]/[isDev]/[isStaging]/[isProd] reflect
  /// it.
  static void loadFromString(
    String content, {
    VeloraEnvironment? environment,
    bool merge = false,
  }) {
    if (environment != null) {
      current = environment;
    }
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

  /// Clears all loaded values, resets [isLoaded] to false, and clears any
  /// explicitly-set/loaded [current] override (so it re-resolves from the
  /// `VELORA_ENV` compile-time define on next read). Intended for tests, to
  /// avoid state leaking between test cases.
  static void reset() {
    _values = const {};
    _isLoaded = false;
    _current = null;
  }
}
