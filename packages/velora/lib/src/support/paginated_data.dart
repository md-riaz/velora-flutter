class PaginatedData<T> {
  final List<T> data;
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;

  const PaginatedData({
    required this.data,
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
  });

  bool get hasMore => currentPage < lastPage;

  /// Parses a paginated API response into [PaginatedData].
  ///
  /// The default key names match the common `{data: [], meta: {current_page,
  /// last_page, per_page, total}}` envelope. Override them for your backend:
  ///
  /// ```dart
  /// // Django REST Framework: {"count": 73, "results": [...]}
  /// PaginatedData.fromJson(json, parser,
  ///   dataKey: 'results',
  ///   metaKey: null,        // meta is top-level
  ///   totalKey: 'count',
  ///   currentPageKey: 'page',
  ///   lastPageKey: 'total_pages',
  ///   perPageKey: 'page_size',
  /// )
  /// ```
  factory PaginatedData.fromJson(
    Map<String, dynamic> json,
    T Function(Object? value) parser, {
    String dataKey = 'data',
    String? metaKey = 'meta',
    String currentPageKey = 'current_page',
    String lastPageKey = 'last_page',
    String perPageKey = 'per_page',
    String totalKey = 'total',
  }) {
    final meta = metaKey != null
        ? (json[metaKey] as Map<String, dynamic>? ?? const {})
        : json;
    final items = json[dataKey] as List? ?? const [];
    return PaginatedData<T>(
      data: items.map(parser).toList(growable: false),
      currentPage: (meta[currentPageKey] as num?)?.toInt() ?? 1,
      lastPage: (meta[lastPageKey] as num?)?.toInt() ?? 1,
      perPage: (meta[perPageKey] as num?)?.toInt() ?? items.length,
      total: (meta[totalKey] as num?)?.toInt() ?? items.length,
    );
  }
}
