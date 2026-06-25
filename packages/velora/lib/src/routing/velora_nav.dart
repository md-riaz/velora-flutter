import 'package:get/get.dart';

import 'velora_route_guard.dart';

class VeloraNav extends GetxService {
  Future<T?>? to<T>(String route, {dynamic arguments}) {
    return Get.toNamed<T>(route, arguments: arguments);
  }

  Future<T?>? off<T>(String route, {dynamic arguments}) {
    return Get.offNamed<T>(route, arguments: arguments);
  }

  Future<T?>? offAll<T>(String route, {dynamic arguments}) {
    return Get.offAllNamed<T>(route, arguments: arguments);
  }

  void back<T>({T? result}) => Get.back<T>(result: result);

  /// Wraps [guards] in a [VeloraMiddleware] list ready for [GetPage.middlewares].
  ///
  /// ```dart
  /// GetPage(
  ///   name: '/dashboard',
  ///   page: () => DashboardPage(),
  ///   middlewares: Velora.nav.guard([VeloraAuthGuard()]),
  /// )
  /// ```
  List<GetMiddleware> guard(List<VeloraRouteGuard> guards) =>
      [VeloraMiddleware(guards: guards)];

  /// Shorthand: require the user to be authenticated.
  List<GetMiddleware> get authOnly => guard(const [VeloraAuthGuard()]);

  /// Shorthand: require the user to be a guest (not authenticated).
  List<GetMiddleware> guestOnly({String authenticatedRoute = '/'}) =>
      guard([VeloraGuestGuard(authenticatedRoute: authenticatedRoute)]);
}
