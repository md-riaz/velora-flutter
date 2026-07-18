/// Canonical feature-flag identifiers, shared across modules so the same string
/// literal isn't duplicated (and can't silently drift) between the settings
/// catalog and notification payloads.
abstract final class AppFeatures {
  static const voice = 'chat.voice';
  static const canvas = 'chat.canvas';
  static const codeInterpreter = 'advanced.code_interpreter';
  static const artifacts = 'chat.artifacts';
}
