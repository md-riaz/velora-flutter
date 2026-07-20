/// The set of app environments/flavors `velora_env` understands.
///
/// This mirrors Laravel's `APP_ENV` convention (`local`/`staging`/
/// `production`) trimmed to the three flavors Velora apps actually ship:
/// [dev], [staging], and [prod].
enum VeloraEnvironment {
  /// Local development. The default when nothing else is configured.
  dev,

  /// Pre-production / QA.
  staging,

  /// Production.
  prod;

  /// Human-readable label, currently identical to [name].
  String get label => name;

  /// Parses a raw string (e.g. from `--dart-define=VELORA_ENV=...` or a
  /// `.env` file's `APP_ENV` key) into a [VeloraEnvironment].
  ///
  /// Matching is case-insensitive and accepts common aliases:
  /// - `dev`, `development` → [dev]
  /// - `staging`, `stag` → [staging]
  /// - `prod`, `production` → [prod]
  ///
  /// Anything else — including `null` or an empty string — resolves to
  /// [fallback] (defaults to [dev]).
  static VeloraEnvironment parse(
    String? raw, {
    VeloraEnvironment fallback = VeloraEnvironment.dev,
  }) {
    final value = raw?.trim().toLowerCase();
    if (value == null || value.isEmpty) return fallback;

    switch (value) {
      case 'dev':
      case 'development':
        return VeloraEnvironment.dev;
      case 'staging':
      case 'stag':
        return VeloraEnvironment.staging;
      case 'prod':
      case 'production':
        return VeloraEnvironment.prod;
      default:
        return fallback;
    }
  }
}
