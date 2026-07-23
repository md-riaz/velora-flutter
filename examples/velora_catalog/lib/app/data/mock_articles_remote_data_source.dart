import 'package:dio/dio.dart';
import 'package:velora/velora.dart' hide Response;
import 'package:velora_offline/velora_offline.dart';

import 'article.dart';

/// Stands in for a real REST API (e.g. `GET /articles`, `GET /articles/:id`)
/// backing the catalog.
///
/// This is the teaching centerpiece of `velora_catalog`: it is injected
/// straight into a [VeloraCachedRepository] as its `remote`, and its only
/// job in this demo is to be toggleable "unreachable" so you can watch that
/// repository fall back to the local `velora_db` cache. It is deliberately
/// the mirror image of `velora_chat`'s `MockChatServerInterceptor` — that
/// one simulates a server *receiving* writes; this one simulates a server
/// *serving* reads (and refusing to, on demand).
///
/// Both [index] and [show] simulate real network latency with a short
/// delay, then check the injected [ToggleConnectivitySource]:
/// - **Online** — returns data straight out of the fixed in-memory
///   [_seedArticles] list, exactly like a real API response.
/// - **Offline** — throws a [DioException] with
///   [DioExceptionType.connectionError], the same shape a real `dio` call
///   throws when it can't reach a server at all. `VeloraCachedRepository`'s
///   `defaultIsOfflineError` recognizes this exact exception shape and
///   falls back to serving the local cache instead of rethrowing.
///
/// [store]/[update]/[destroy] all throw [UnsupportedError] — this demo is a
/// read-only catalog/reader, so `VeloraCachedRepository`'s write path (which
/// always delegates to the remote as the source of truth) is intentionally
/// left unexercised here.
class MockArticlesRemoteDataSource implements VeloraRemoteDataSource<Article, String> {
  final ToggleConnectivitySource _connectivity;

  MockArticlesRemoteDataSource(this._connectivity);

  static final List<Article> _seedArticles = [
    Article(
      id: 'a1',
      title: 'Getting Started with Velora',
      summary:
          'A tour of the framework: boot, plugins, controllers, and the '
          'facade-style API that ties it all together.',
      author: 'Velora Team',
      updatedAt: DateTime(2026, 1, 12).millisecondsSinceEpoch,
    ),
    Article(
      id: 'a2',
      title: 'Reactive Reads with velora_db',
      summary:
          'How `VeloraTable.watchQuery` turns a plain SQLite table into a '
          'live stream your controllers can bind straight into the UI.',
      author: 'Amina K.',
      updatedAt: DateTime(2026, 2, 3).millisecondsSinceEpoch,
    ),
    Article(
      id: 'a3',
      title: 'Offline-First vs. Network-First',
      summary:
          'Two shapes for the same problem: `velora_offline`\'s reactive '
          'local store with a write outbox, versus `velora_db`\'s '
          '`VeloraCachedRepository` read-through cache. When to use which.',
      author: 'Sam R.',
      updatedAt: DateTime(2026, 3, 21).millisecondsSinceEpoch,
    ),
    Article(
      id: 'a4',
      title: 'Designing a Write Outbox',
      summary:
          'What it takes to queue writes made while offline and replay them '
          'safely on reconnect, without double-submitting.',
      author: 'Velora Team',
      updatedAt: DateTime(2026, 4, 2).millisecondsSinceEpoch,
    ),
    Article(
      id: 'a5',
      title: 'Migrations Without Codegen',
      summary:
          'Why `velora_db` migrations are plain SQL in a `VeloraMigration` '
          'subclass instead of a generated schema — and what you give up.',
      author: 'Priya N.',
      updatedAt: DateTime(2026, 4, 18).millisecondsSinceEpoch,
    ),
    Article(
      id: 'a6',
      title: 'Constructor DI in Practice',
      summary:
          'Why every Velora module builds its controller\'s dependencies '
          'explicitly in a factory instead of reaching into `Get.find` from '
          'inside the controller.',
      author: 'Sam R.',
      updatedAt: DateTime(2026, 5, 9).millisecondsSinceEpoch,
    ),
    Article(
      id: 'a7',
      title: 'Testing Offline Flows',
      summary:
          'Using `ToggleConnectivitySource` and an in-memory drift database '
          'to exercise offline behavior deterministically, with no real '
          'network or platform channel in sight.',
      author: 'Amina K.',
      updatedAt: DateTime(2026, 6, 5).millisecondsSinceEpoch,
    ),
    Article(
      id: 'a8',
      title: 'Shipping a PWA with Velora',
      summary:
          '`velora make:pwa` in one command: what it generates, and how to '
          'verify a service worker actually caches what you think it does.',
      author: 'Priya N.',
      updatedAt: DateTime(2026, 6, 30).millisecondsSinceEpoch,
    ),
  ];

  Future<void> _simulateLatency() {
    return Future<void>.delayed(const Duration(milliseconds: 500));
  }

  Future<void> _throwIfOffline(String path) async {
    if (_connectivity.isOnline) return;
    throw DioException(
      requestOptions: RequestOptions(path: path),
      type: DioExceptionType.connectionError,
      error: 'No route to host (simulated by ToggleConnectivitySource).',
    );
  }

  @override
  Future<List<Article>> index() async {
    await _simulateLatency();
    await _throwIfOffline('/articles');
    return List.unmodifiable(_seedArticles);
  }

  @override
  Future<Article> show(String id) async {
    await _simulateLatency();
    await _throwIfOffline('/articles/$id');
    for (final article in _seedArticles) {
      if (article.id == id) return article;
    }
    // A real, well-formed 404 -- the request *did* reach the server, so
    // this must not be mistaken for an offline condition. It deliberately
    // is not classified as "offline" by `defaultIsOfflineError`, so
    // `VeloraCachedRepository` rethrows it instead of falling back to the
    // cache.
    throw DioException(
      requestOptions: RequestOptions(path: '/articles/$id'),
      type: DioExceptionType.badResponse,
      response: Response<Map<String, dynamic>>(
        requestOptions: RequestOptions(path: '/articles/$id'),
        statusCode: 404,
        data: const {'message': 'Article not found'},
      ),
    );
  }

  @override
  Future<Article> store(Map<String, dynamic> data) {
    throw UnsupportedError(
      'MockArticlesRemoteDataSource is read-only -- velora_catalog is a '
      'reader demo, not a CMS. Writing articles is intentionally out of '
      'scope.',
    );
  }

  @override
  Future<Article> update(String id, Map<String, dynamic> data) {
    throw UnsupportedError(
      'MockArticlesRemoteDataSource is read-only -- see store().',
    );
  }

  @override
  Future<void> destroy(String id) {
    throw UnsupportedError(
      'MockArticlesRemoteDataSource is read-only -- see store().',
    );
  }
}
