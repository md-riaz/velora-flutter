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

  factory PaginatedData.fromJson(
    Map<String, dynamic> json,
    T Function(Object? value) parser,
  ) {
    final meta = json['meta'] as Map<String, dynamic>? ?? const {};
    final items = json['data'] as List? ?? const [];
    return PaginatedData<T>(
      data: items.map(parser).toList(growable: false),
      currentPage: (meta['current_page'] as num?)?.toInt() ?? 1,
      lastPage: (meta['last_page'] as num?)?.toInt() ?? 1,
      perPage: (meta['per_page'] as num?)?.toInt() ?? items.length,
      total: (meta['total'] as num?)?.toInt() ?? items.length,
    );
  }
}
