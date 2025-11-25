import 'dart:async';

import 'package:draftmode_geofence/geofence.dart';
import 'package:draftmode_notifier/notifier.dart';
import 'package:draftmode_notifier_example/entity/config.dart';
import 'package:draftmode_ui/components.dart';
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
    unawaited(_initGeofence());
    // config notifier
    unawaited(_initNotifier());
  }

  Future<void> _initNotifier() async {
    await DraftModeNotifier.instance.init();
    final configs = await GeofenceConfigStore().loadAll();
    for (final config in configs) {
      final String fenceId = config.id;
      debugPrint("register [$fenceId] _onEnterNotify");
      DraftModeNotifier.instance.registerConsumer(
        payload: fenceId,
        handler: _onEnterNotify,
      );
    }
  }

  Future<void> _initGeofence() async {
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
        onEvent: (DraftModeGeofenceEvent event) =>
            _handleGeofenceEvent(config.id, event),
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

  Future<void> _onEnterNotify(DraftModeNotificationResponse response) async {
    await DraftModeUIDialog.show(
      title: 'Notification',
      message: "You've tapped on the notification (${response.payload})",
    );
  }

  Future<bool> _handleGeofenceEvent(
    String fenceId,
    DraftModeGeofenceEvent event,
  ) async {
    if (event.entering) {
      debugPrint("[$fenceId] onEnter ${event.entering}");
      await DraftModeNotifier.instance.pushNotification(
        title: "Enter geofence",
        body: "You've entered, press to continue",
        payload: fenceId,
      );
    } else {
      debugPrint("[$fenceId] onExit ${event.entering}");
    }
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

  Future<void> _resetGeofence() async {
    await GeofenceConfigStore().resetToDefaults();
    await _initGeofence();
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
    await _initGeofence();
  }

  Future<void> _deleteFence(String id) async {
    final store = GeofenceConfigStore();
    final configs = await store.loadAll();
    final updated = configs.where((config) => config.id != id).toList();
    await store.saveAll(updated);
    await _initGeofence();
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
        onResetGeofences: _resetGeofence,
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
