import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:geolocator/geolocator.dart';

import 'listener.dart';
import 'notifier.dart';
import 'state/entity.dart';
import 'state/policy.dart';
import 'state/storage.dart';

/// Coordinates listener callbacks, optional confirmations, and persisted state.
class DraftModeGeofenceController {
  final DraftModeGeofenceListener _listener;
  final LocationAccuracy _accuracy;

  DraftModeGeofenceController({
    required DraftModeGeofenceListener listener,
    LocationAccuracy? accuracy
  }) : _listener = listener,
       _accuracy = accuracy ?? LocationAccuracy.best
  ;

  StreamSubscription<DraftModeGeofenceEvent>? _geofenceSubscription;
  DraftModeGeofenceNotifier? _notifier;

  /// Cancels listeners and stops the geofence stream.
  Future<void> dispose() async {
    await _geofenceSubscription?.cancel();
    await _listener.stop();
  }

  /// Starts tracking and reacts to enter/exit events from the listener.
  Future<void> startGeofence() async {
    _notifier = _listener.notifier;
    debugPrint("geofenceController:startGeofence with lng:${_listener.centerLng}, lat:${_listener.centerLat}");
    await _listener.start(
      distanceFilterMeters: 20,
      accuracy: _accuracy,
    );
    _geofenceSubscription = _listener.events.listen((event) async {
      debugPrint("geofenceController:lat:${event.position.latitude.toString()}:lng:${event.position.longitude.toString()}");
      if (event.entering) {
        debugPrint("geofenceController:entering");
        final bool updateState = await _updateState();
        if (updateState) {
          await _saveState(DraftModeGeofenceStateEntity.stateEnter, true);
          await _listener.onEnter();
        }
      } else {
        final confirm = await _confirmExit();
        if (confirm) {
          await _saveState(DraftModeGeofenceStateEntity.stateExit, true);
          debugPrint("geofenceController:exit (confirmed)");
          await _listener.onExit();
        } else {
          await _saveState(DraftModeGeofenceStateEntity.stateExit, false);
          debugPrint("geofenceController:exit (not confirmed)");
        }
      }
    });
  }

  /// Validates whether we can emit another enter event based on stored state.
  Future<bool> _updateState() async {
    final lastState = await _readState();
    return shouldStartTracking(
      lastState: lastState,
      notifier: _notifier,
    );
  }

  /// Persists the newest geofence state.
  Future<void> _saveState(String state, bool approved) async {
    debugPrint("geofenceController:saveState: state:$state, approved:$approved");
    await DraftModeGeofenceStateStorage().save(state, approved);
  }

  /// Loads the previously persisted geofence state, if any.
  Future<DraftModeGeofenceStateEntity?> _readState() async {
    final lastState = await DraftModeGeofenceStateStorage().read();
    if (lastState != null) {
      debugPrint("geofenceController:readState, lastEventDate: ${lastState.eventDate.toIso8601String()}, lastState: ${lastState.state}, lastApproved: ${lastState.approved}");
    } else {
      debugPrint("geofenceController:readState, no last state found");
    }
    return lastState;
  }

  /// Prompts the notifier for an exit confirmation when configured.
  Future<bool> _confirmExit() async {
    if (_notifier == null) return true;
    return false;
  }

}
