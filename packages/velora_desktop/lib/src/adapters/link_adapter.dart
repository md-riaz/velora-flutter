import 'package:app_links/app_links.dart';

import '../desktop_ports.dart';

/// [VeloraDesktopLinkPort] over `app_links`.
class AppLinksAdapter implements VeloraDesktopLinkPort {
  AppLinksAdapter();

  final AppLinks _appLinks = AppLinks();

  @override
  Future<Uri?> initialLink() => _appLinks.getInitialLink();

  @override
  Stream<Uri> get links => _appLinks.uriLinkStream;
}
