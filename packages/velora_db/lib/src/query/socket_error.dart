/// Conditional export of the platform-appropriate [isSocketException]
/// check, so importing `velora_cached_repository.dart` (and therefore
/// `package:velora_db/velora_db.dart`) never pulls `dart:io` into a Flutter
/// Web build, where it fails to compile.
///
/// Mirrors the pattern in `../driver/db_factory.dart`.
library;

export 'socket_error_io.dart' if (dart.library.js_interop) 'socket_error_web.dart';
