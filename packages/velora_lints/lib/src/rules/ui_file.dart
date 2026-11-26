bool isUiFile(String path, {bool includeModules = false}) {
  final parts = path.replaceAll('\\', '/').split('/');
  if (parts.contains('test')) return false;
  for (var i = 0; i < parts.length - 1; i++) {
    if (parts[i] == 'resources' && parts[i + 1] == 'theme') return false;
  }
  final file = parts.last;
  return file.endsWith('_page.dart') ||
      file.endsWith('_widget.dart') ||
      parts.contains('pages') ||
      parts.contains('widgets') ||
      (includeModules && parts.contains('modules'));
}
