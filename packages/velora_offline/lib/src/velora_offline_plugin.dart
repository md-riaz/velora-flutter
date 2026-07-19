import 'package:velora/velora.dart';

import 'connectivity_service.dart';
import 'connectivity_source.dart';
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

  VeloraOfflinePlugin({ConnectivitySource? source})
      : source = source ?? ConnectivityPlusSource();

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

    context.addInterceptor(OfflineQueueInterceptor(queue));

    connectivity.onOnline(() => queue.flush());

    context.onBeforeLogout(() async {
      await queue.clear();
    });
  }
}

/// Package-level facade for the services [VeloraOfflinePlugin] registers.
/// Kept out of core `Velora` so the framework stays agnostic of this plugin.
class VeloraOffline {
  const VeloraOffline._();

  static ConnectivityService get connectivity => Get.find<ConnectivityService>();

  static bool get isOnline => connectivity.isOnline.value;

  static OfflineRequestQueue get queue => Get.find<OfflineRequestQueue>();
}
