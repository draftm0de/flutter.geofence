import 'dart:async';

import 'package:geolocator/geolocator.dart';

import 'controller.dart';
import 'listener.dart';
import 'state/entity.dart';
import 'state/storage.dart';

/// Keeps track of multiple geofence controllers/listeners that should run in
/// parallel. Each fence is keyed by an identifier so their persisted states do
/// not collide inside [SharedPreferences].
class DraftModeGeofenceRegistry {
  DraftModeGeofenceRegistry({
    LocationAccuracy accuracy = LocationAccuracy.best,
    int expireUnapprovedMinutes = 60,
  })  : _defaultAccuracy = accuracy,
        _defaultExpireUnapprovedMinutes = expireUnapprovedMinutes;

  final Map<String, DraftModeGeofenceController> _controllers = {};
  final LocationAccuracy _defaultAccuracy;
  final int _defaultExpireUnapprovedMinutes;

  /// Registers (or replaces) a fence and immediately starts listening for
  /// events.
  Future<void> registerFence({
    required String fenceId,
    required DraftModeGeofenceListener listener,
    LocationAccuracy? accuracy,
    int? expireUnapprovedMinutes,
  }) async {
    await unregisterFence(fenceId);
    final controller = DraftModeGeofenceController(
      listener: listener,
      accuracy: accuracy ?? _defaultAccuracy,
      expireUnapprovedMinutes:
          expireUnapprovedMinutes ?? _defaultExpireUnapprovedMinutes,
      fenceId: fenceId,
    );
    _controllers[fenceId] = controller;
    await controller.startGeofence();
  }

  /// Returns the controller for an already registered fence, if any.
  DraftModeGeofenceController? controllerFor(String fenceId) =>
      _controllers[fenceId];

  /// Convenience helper for callers that only need the persisted fence state.
  Future<DraftModeGeofenceStateEntity?> readFenceState(String fenceId) async {
    final controller = _controllers[fenceId];
    if (controller != null) {
      return controller.getLastKnownState();
    }
    return DraftModeGeofenceStateStorage(fenceId: fenceId).read();
  }

  /// Stops tracking a fence and disposes its controller.
  Future<void> unregisterFence(String fenceId) async {
    final controller = _controllers.remove(fenceId);
    if (controller != null) {
      await controller.dispose();
    }
  }

  /// Stops every active fence listener and clears the registry.
  Future<void> dispose() async {
    final disposers = _controllers.values
        .map((controller) => controller.dispose())
        .toList(growable: false);
    _controllers.clear();
    await Future.wait(disposers);
  }

  /// Snapshot of all registered identifiers.
  List<String> get registeredFenceIds =>
      _controllers.keys.toList(growable: false);
}
