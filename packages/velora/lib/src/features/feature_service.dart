import 'package:get/get.dart';

import '../core/velora_facade.dart';
import '../core/velora_lifecycle.dart';

class VeloraFeature {
  final String id;
  final String name;
  final String? permission;
  final List<VeloraMenuItem> menuItems;
  final List<Future<void> Function()> disposers;
  final bool disposeOnLogout;

  const VeloraFeature({
    required this.id,
    required this.name,
    this.permission,
    this.menuItems = const [],
    this.disposers = const [],
    this.disposeOnLogout = true,
  });
}

class VeloraMenuItem {
  final String label;
  final String route;
  final String? permission;

  const VeloraMenuItem({
    required this.label,
    required this.route,
    this.permission,
  });
}

class FeatureService extends GetxService with VeloraLogoutAwareDefaults {
  final Map<String, VeloraFeature> _registered = {};
  final RxSet<String> _enabled = <String>{}.obs;
  final List<Future<void> Function()> _userScopeDisposers = [];
  final bool Function(String permission)? permissionResolver;

  FeatureService({this.permissionResolver});

  bool _can(String permission) =>
      (permissionResolver ?? Velora.permission.can)(permission);

  void register(VeloraFeature feature) {
    _registered[feature.id] = feature;
  }

  void registerAll(Iterable<VeloraFeature> features) {
    for (final feature in features) {
      register(feature);
    }
  }

  void registerUserScopeDisposer(Future<void> Function() disposer) {
    _userScopeDisposers.add(disposer);
  }

  void enable(String featureId) => _enabled.add(featureId);

  void disable(String featureId) => _enabled.remove(featureId);

  void syncFromUserFeatures(Iterable<String> features) {
    _enabled.assignAll(features);
  }

  bool enabled(String featureId) => _enabled.contains(featureId);

  bool canAccess(String featureId) {
    final feature = _registered[featureId];
    if (feature == null || !enabled(featureId)) return false;
    final permission = feature.permission;
    return permission == null || _can(permission);
  }

  List<VeloraMenuItem> get menuItems {
    return _registered.values
        .where((feature) => canAccess(feature.id))
        .expand((feature) => feature.menuItems)
        .where(
          (item) => item.permission == null || _can(item.permission!),
        )
        .toList(growable: false);
  }

  Future<void> flushUserScope() async {
    final enabledScope = Set<String>.from(_enabled);
    _enabled.clear();

    await _dispose(_userScopeDisposers);
    _userScopeDisposers.clear();

    for (final featureId in enabledScope) {
      final feature = _registered[featureId];
      if (feature != null && feature.disposeOnLogout) {
        await _dispose(feature.disposers);
      }
    }
  }

  @override
  Future<void> onLogoutDispose() => flushUserScope();

  Future<void> _dispose(Iterable<Future<void> Function()> disposers) async {
    for (final disposer in disposers) {
      try {
        await disposer();
      } catch (_) {
        // Feature teardown must not block local logout completion.
      }
    }
  }
}
