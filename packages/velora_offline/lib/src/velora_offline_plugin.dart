import 'dart:async';

import 'package:dio/dio.dart';
import 'package:velora/velora.dart';
import 'package:velora_db/velora_db.dart';

import 'connectivity_service.dart';
import 'connectivity_source.dart';
import 'offline_first_repository.dart';
import 'offline_queue_interceptor.dart';
import 'offline_request_queue.dart';

/// The first official Velora plugin: connectivity awareness plus an offline
/// write queue that replays automatically on reconnect.
///
/// ```dart
/// await Velora.boot(
///   config: myConfig,
///   plugins: [VeloraOfflinePlugin()],
/// );
/// ```
class VeloraOfflinePlugin extends VeloraPlugin {
  final ConnectivitySource source;

  /// Additional request paths to never queue, merged with the auth
  /// endpoints ([VeloraAuthConfig.loginEndpoint],
  /// [VeloraAuthConfig.logoutEndpoint], [VeloraAuthConfig.meEndpoint]), which
  /// are always excluded regardless of this set.
  final Set<String> excludedPaths;

  /// Optional additional predicate for excluding requests from the queue.
  /// Return `false` to skip queuing a given request.
  final bool Function(RequestOptions options)? shouldQueue;

  VeloraOfflinePlugin({
    ConnectivitySource? source,
    this.excludedPaths = const {},
    this.shouldQueue,
  }) : source = source ?? ConnectivityPlusSource();

  @override
  String get name => 'velora_offline';

  @override
  Future<void> register(VeloraContext context) async {
    final connectivity = await ConnectivityService(source).init();
    context.put<ConnectivityService>(connectivity);

    final queue = await OfflineRequestQueue(
      storage: context.find<VeloraStorageService>(),
      api: context.find<VeloraApiService>(),
    ).load();
    context.put<OfflineRequestQueue>(queue);

    final auth = context.config.auth;
    context.addInterceptor(
      OfflineQueueInterceptor(
        queue,
        excludedPaths: {
          auth.loginEndpoint,
          auth.logoutEndpoint,
          auth.meEndpoint,
          ...excludedPaths,
        },
        shouldQueue: shouldQueue,
      ),
    );

    connectivity.onOnline(() => queue.flush());

    context.onBeforeLogout(() async {
      await queue.clear();
    });

    // Replay anything persisted from a previous session immediately if
    // we're already online, rather than waiting for a connectivity cycle.
    if (connectivity.isOnline.value && queue.pending.isNotEmpty) {
      unawaited(queue.flush());
    }
  }
}

/// Package-level facade for the services [VeloraOfflinePlugin] registers.
/// Kept out of core `Velora` so the framework stays agnostic of this plugin.
class VeloraOffline {
  const VeloraOffline._();

  static ConnectivityService get connectivity => Get.find<ConnectivityService>();

  static bool get isOnline => connectivity.isOnline.value;

  static OfflineRequestQueue get queue => Get.find<OfflineRequestQueue>();

  /// Builds a [VeloraOfflineFirstRepository] over [table], resolving the
  /// registered [OfflineRequestQueue] and [ConnectivityService] from GetX.
  /// Requires both VeloraOfflinePlugin and VeloraDbPlugin to have booted.
  static VeloraOfflineFirstRepository<T, ID> offlineFirst<T, ID>({
    required VeloraTable<T, ID> table,
    required String endpoint,
  }) {
    return VeloraOfflineFirstRepository<T, ID>(
      table: table,
      queue: queue,
      connectivity: connectivity,
      endpoint: endpoint,
    );
  }
}
