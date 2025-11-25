import 'config.dart';
import 'listener.dart';
import 'registry.dart';

typedef DraftModeGeofenceListenerBuilder = DraftModeGeofenceListener Function(
  DraftModeGeofenceConfig config,
  Future<bool> Function(DraftModeGeofenceEvent event) onEvent,
);

typedef DraftModeGeofenceRegistryBuilder = DraftModeGeofenceRegistry Function();

/// Helper that wires multiple [DraftModeGeofenceListener]s into a
/// [DraftModeGeofenceRegistry] from a list of configs.
class DraftModeGeofenceFactory {
  DraftModeGeofenceFactory({
    DraftModeGeofenceRegistryBuilder? registryBuilder,
    DraftModeGeofenceListenerBuilder? listenerBuilder,
  })  : _registryBuilder = registryBuilder ?? DraftModeGeofenceRegistry.new,
        _listenerBuilder = listenerBuilder ?? _defaultListenerBuilder;

  final DraftModeGeofenceRegistryBuilder _registryBuilder;
  final DraftModeGeofenceListenerBuilder _listenerBuilder;
  DraftModeGeofenceRegistry? _registry;
  final Map<String, DraftModeGeofenceListener> _listeners = {};

  bool get isInitialized => _registry != null;
  DraftModeGeofenceRegistry? get registry => _registry;
  Map<String, DraftModeGeofenceListener> get listeners =>
      Map.unmodifiable(_listeners);
  DraftModeGeofenceListener? listenerFor(String fenceId) => _listeners[fenceId];
  List<String> get registeredFenceIds =>
      List<String>.unmodifiable(_listeners.keys);

  /// Registers all [configs] with a fresh registry instance.
  ///
  /// A config-specific [DraftModeGeofenceConfig.onEvent] takes precedence over
  /// the optional [onEvent] argument. When neither is provided, movements are
  /// auto-approved.
  Future<DraftModeGeofenceRegistry> init(
    List<DraftModeGeofenceConfig> configs, {
    Future<bool> Function(String fenceId, DraftModeGeofenceEvent event)?
        onEvent,
  }) async {
    await dispose();
    final registry = _registryBuilder();
    for (final config in configs) {
      final handler = _resolveHandler(config, onEvent);
      final listener = _listenerBuilder(config, handler);
      await registry.registerFence(
        fenceId: config.id,
        listener: listener,
      );
      _listeners[config.id] = listener;
    }
    _registry = registry;
    return registry;
  }

  /// Tears down the currently registered listeners and their controllers.
  Future<void> dispose() async {
    _listeners.clear();
    final registry = _registry;
    _registry = null;
    if (registry != null) {
      await registry.dispose();
    }
  }

  Future<bool> Function(DraftModeGeofenceEvent event) _resolveHandler(
    DraftModeGeofenceConfig config,
    Future<bool> Function(String fenceId, DraftModeGeofenceEvent event)?
        onEvent,
  ) {
    final configHandler = config.onEvent;
    if (configHandler != null) {
      return configHandler;
    }
    if (onEvent != null) {
      return (DraftModeGeofenceEvent event) => onEvent(config.id, event);
    }
    return _autoApprove;
  }

  static DraftModeGeofenceListener _defaultListenerBuilder(
    DraftModeGeofenceConfig config,
    Future<bool> Function(DraftModeGeofenceEvent event) onEvent,
  ) =>
      DraftModeGeofenceListener(
        centerLat: config.lat,
        centerLng: config.lng,
        radiusMeters: config.radiusMeters,
        onEvent: onEvent,
      );

  static Future<bool> _autoApprove(DraftModeGeofenceEvent event) async => true;
}
