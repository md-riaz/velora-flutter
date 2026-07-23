abstract class AppRoutes {
  static const catalog = '/';
  static const article = '/article/:id';

  /// Builds a concrete `/article/<id>` path for navigation, matching
  /// [article]'s `:id` parameter.
  static String articlePath(String id) => '/article/$id';
}
