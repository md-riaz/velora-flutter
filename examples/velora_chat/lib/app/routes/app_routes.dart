abstract class AppRoutes {
  static const conversations = '/';
  static const chat = '/chat/:id';

  /// Builds a concrete `/chat/<id>` path for navigation, matching [chat]'s
  /// `:id` parameter.
  static String chatPath(String id) => '/chat/$id';
}
