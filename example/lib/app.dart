import 'dart:async';

import 'package:draftmode_geofence/geofence.dart';
import 'package:draftmode_notifier_example/entity/config.dart';
import 'package:flutter/cupertino.dart';

import 'screen/home.dart';

class App extends StatefulWidget {
  final GlobalKey<NavigatorState> navigatorKey;
  const App({required this.navigatorKey, super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  DraftModeGeofenceRegistry? _registry;
  final List<StreamSubscription<DraftModeGeofenceEvent>> _eventSubscriptions =
      [];
  final Map<String, DraftModeGeofenceStateEntity?> _persistedStates = {};
  final Map<String, bool> _liveStates = {};
  List<GeofenceConfig> _configs = const [];
  bool _isLoading = true;
  @override
  void initState() {
    super.initState();
    // config geofence
    unawaited(_initGeofences());

    /*_geofencingController = TimeTacGeofencingController(
      navigatorKey: navigatorKey,
      isAppInForeground: () => _isAppInForeground,
      isMounted: () => mounted,
    );*/
  }

  Future<void> _initGeofences() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }
    await _disposeRegistry();
    _persistedStates.clear();
    _liveStates.clear();
    final configs = await GeofenceConfigStore().loadAll();
    final registry = DraftModeGeofenceRegistry();
    for (final config in configs) {
      final listener = DraftModeGeofenceListener(
        centerLat: config.lat,
        centerLng: config.lng,
        radiusMeters: config.radiusMeters,
        onEnter: (DraftModeGeofenceEvent event) => _onEnter(config.id, event),
        onExit: (DraftModeGeofenceEvent event) => _onExit(config.id, event),
      );

      _eventSubscriptions.add(
        listener.events.listen((event) {
          if (!mounted) return;
          setState(() {
            _liveStates[config.id] = event.entering;
          });
          _refreshFenceState(config.id);
        }),
      );

      await registry.registerFence(
        fenceId: config.id,
        listener: listener,
      );

      final state = await registry.readFenceState(config.id);
      _persistedStates[config.id] = state;
    }

    if (!mounted) {
      await registry.dispose();
      return;
    }

    setState(() {
      _registry = registry;
      _configs = configs;
      _isLoading = false;
    });
  }

  Future<bool> _onEnter(String fenceId, DraftModeGeofenceEvent event) async {
    debugPrint("[$fenceId] onEnter");
    return true;
  }

  Future<bool> _onExit(String fenceId, DraftModeGeofenceEvent event) async {
    debugPrint("[$fenceId] onExit");
    return true;
  }

  Future<void> _refreshFenceState(String fenceId) async {
    final registry = _registry;
    if (registry == null) return;
    final state = await registry.readFenceState(fenceId);
    if (!mounted) return;
    setState(() {
      _persistedStates[fenceId] = state;
    });
  }

  Future<void> _refreshAllFenceStates() async {
    for (final config in _configs) {
      await _refreshFenceState(config.id);
    }
  }

  Future<void> _resetGeofences() async {
    await GeofenceConfigStore().resetToDefaults();
    await _initGeofences();
  }

  Future<void> _addFence({
    required String label,
    required double latitude,
    required double longitude,
    required double radiusMeters,
  }) async {
    final store = GeofenceConfigStore();
    final configs = await store.loadAll();
    final id = _generateFenceId(label, configs);
    final updated = [
      ...configs,
      GeofenceConfig(
        id: id,
        label: label,
        lat: latitude,
        lng: longitude,
        radiusMeters: radiusMeters,
      ),
    ];
    await store.saveAll(updated);
    await _initGeofences();
  }

  Future<void> _deleteFence(String id) async {
    final store = GeofenceConfigStore();
    final configs = await store.loadAll();
    final updated = configs.where((config) => config.id != id).toList();
    await store.saveAll(updated);
    await _initGeofences();
  }

  String _generateFenceId(String label, List<GeofenceConfig> existing) {
    final normalized = label
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'-{2,}'), '-')
        .replaceAll(RegExp(r'^-|-$'), '')
        .trim();
    final base = normalized.isEmpty ? 'fence' : normalized;
    var candidate = base;
    var suffix = 2;
    final used = existing.map((config) => config.id).toSet();
    while (used.contains(candidate)) {
      candidate = '$base-$suffix';
      suffix++;
    }
    return candidate;
  }

  @override
  void dispose() {
    unawaited(_disposeRegistry());
    super.dispose();
  }

  Future<void> _disposeRegistry() async {
    for (final sub in _eventSubscriptions) {
      await sub.cancel();
    }
    _eventSubscriptions.clear();
    final registry = _registry;
    _registry = null;
    if (registry != null) {
      await registry.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoApp(
      debugShowCheckedModeBanner: false,
      navigatorKey: widget.navigatorKey,
      home: HomeScreen(
        configs: _configs,
        isLoading: _isLoading,
        liveStates: _liveStates,
        persistedStates: _persistedStates,
        onRefreshStates: _refreshAllFenceStates,
        onResetGeofences: _resetGeofences,
        onAddFence: ({
          required String label,
          required double latitude,
          required double longitude,
          required double radiusMeters,
        }) =>
            _addFence(
          label: label,
          latitude: latitude,
          longitude: longitude,
          radiusMeters: radiusMeters,
        ),
        onDeleteFence: _deleteFence,
      ),
    );
  }
}
