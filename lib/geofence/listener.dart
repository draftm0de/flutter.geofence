import 'dart:async';
import 'dart:math' show cos, sqrt, asin, sin;

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import 'notifier.dart';

/// Simple enter/exit stream for a circular geofence.
class DraftModeGeofenceEvent {
  final bool entering; // true = enter, false = exit
  final Position position;
  DraftModeGeofenceEvent.enter(this.position) : entering = true;
  DraftModeGeofenceEvent.exit(this.position) : entering = false;
}

/// Emits `DraftModeGeofenceEvent`s when the user crosses the configured radius.
class DraftModeGeofenceListener {
  final double centerLat;
  final double centerLng;
  final double radiusMeters;
  final Future<bool> Function(DraftModeGeofenceEvent event) onEnter;
  final Future<bool> Function(DraftModeGeofenceEvent event) onExit;
  final DraftModeGeofenceNotifier? notifier;

  StreamSubscription<Position>? _sub;
  final _controller = StreamController<DraftModeGeofenceEvent>.broadcast();
  bool? _isInside; // unknown at start

  DraftModeGeofenceListener({
    required this.centerLat,
    required this.centerLng,
    required this.radiusMeters,
    required this.onEnter,
    required this.onExit,
    this.notifier
  });

  /// Broadcast stream consumers can listen to for enter/exit events.
  Stream<DraftModeGeofenceEvent> get events => _controller.stream;

  /// Starts listening to position updates and pushes events when the
  /// geofence boundary is crossed.
  Future<void> start({
    int distanceFilterMeters = 15, // movement threshold before updates
    LocationAccuracy accuracy = LocationAccuracy.best,
  }) async {
    // Ensure services + permissions
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw Exception('Location services disabled');
    }
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.denied ||
        perm == LocationPermission.deniedForever) {
      throw Exception('Location permission denied');
    }

    // Initialize inside/outside from current fix
    final initial = await Geolocator.getCurrentPosition(
      locationSettings: LocationSettings(accuracy: accuracy),
    );
    _isInside =
        _distanceMeters(
          initial.latitude,
          initial.longitude,
          centerLat,
          centerLng,
        ) <=
            radiusMeters;

    // Listen for movement
    final settings = LocationSettings(
      accuracy: accuracy,
      distanceFilter: distanceFilterMeters,
      // iOS fine-tuning:
      // timeLimit: Duration(seconds: 0), // optional
    );

    _sub = Geolocator.getPositionStream(locationSettings: settings).listen((
        pos,
        ) {
      final inside =
          _distanceMeters(pos.latitude, pos.longitude, centerLat, centerLng) <=
              radiusMeters;

      if (_isInside == null) {
        _isInside = inside;
      } else if (inside != _isInside) {
        _isInside = inside;
        if (inside) {
          _controller.add(DraftModeGeofenceEvent.enter(pos));
        } else {
          _controller.add(DraftModeGeofenceEvent.exit(pos));
        }
      }
    });
  }

  /// Stops listening to position updates.
  Future<void> stop() async {
    await _sub?.cancel();
    _sub = null;
  }

  /// Helper for tests to inject enter/exit events without real location updates.
  @visibleForTesting
  void emitTestEvent(DraftModeGeofenceEvent event) {
    _controller.add(event);
  }

  /// Allows tests to force `_isInside` back to an unknown state.
  @visibleForTesting
  void resetInsideState() {
    _isInside = null;
  }

  // Haversine (quick) distance
  double _distanceMeters(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371000.0; // Earth radius meters
    final dLat = _deg2rad(lat2 - lat1);
    final dLon = _deg2rad(lon2 - lon1);
    final a =
        (sin(dLat / 2) * sin(dLat / 2)) +
            cos(_deg2rad(lat1)) *
                cos(_deg2rad(lat2)) *
                (sin(dLon / 2) * sin(dLon / 2));
    final c = 2 * asin(sqrt(a));
    return R * c;
  }

  double _deg2rad(double deg) => deg * (3.141592653589793 / 180.0);
}