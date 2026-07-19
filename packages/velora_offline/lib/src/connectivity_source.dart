import 'package:connectivity_plus/connectivity_plus.dart';

/// Abstracts "am I online" so [ConnectivityService] (and anything built on
/// top of it) is unit-testable without the `connectivity_plus` platform
/// channels. Implement this with a fake in tests; use
/// [ConnectivityPlusSource] in real apps.
abstract class ConnectivitySource {
  Future<bool> isConnected();
  Stream<bool> get onConnectivityChanged;
}

/// Wraps `connectivity_plus`'s [Connectivity] singleton, collapsing its
/// [ConnectivityResult] list into a single online/offline boolean.
///
/// `connectivity_plus` reports [ConnectivityResult.none] only when there is
/// no connectivity at all (the returned list is otherwise never empty), so a
/// list containing anything other than a lone `none` is treated as online.
class ConnectivityPlusSource implements ConnectivitySource {
  final Connectivity _connectivity;

  ConnectivityPlusSource({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity();

  @override
  Future<bool> isConnected() async {
    final results = await _connectivity.checkConnectivity();
    return _isOnline(results);
  }

  @override
  Stream<bool> get onConnectivityChanged =>
      _connectivity.onConnectivityChanged.map(_isOnline);

  bool _isOnline(List<ConnectivityResult> results) {
    return results.any((result) => result != ConnectivityResult.none);
  }
}
