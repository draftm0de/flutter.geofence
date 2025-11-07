import 'dart:async';
import 'package:draftmode_geofence/logger.dart';
import 'package:geolocator/geolocator.dart';

import 'listener.dart';
import 'state/entity.dart';
import 'state/policy.dart';
import 'state/storage.dart';

/// Coordinates listener callbacks, optional confirmations, and persisted state.
class DraftModeGeofenceController {
  final DraftModeGeofenceListener _listener;
  final LocationAccuracy _accuracy;
  final int _expireUnapprovedMinutes;

  DraftModeGeofenceController({
    required DraftModeGeofenceListener listener,
    LocationAccuracy? accuracy,
    int? expireUnapprovedMinutes
  }) : _listener = listener,
       _accuracy = accuracy ?? LocationAccuracy.best,
       _expireUnapprovedMinutes = expireUnapprovedMinutes ?? 60
  ;

  DraftModeLogger logger = DraftModeLogger(false);
  StreamSubscription<DraftModeGeofenceEvent>? _geofenceSubscription;

  /// Cancels listeners and stops the geofence stream.
  Future<void> dispose() async {
    await _geofenceSubscription?.cancel();
    await _listener.stop();
  }

  /// Starts tracking and reacts to enter/exit events from the listener.
  Future<void> startGeofence() async {
    logger.notice("geofenceController:startGeofence with lng:${_listener.centerLng}, lat:${_listener.centerLat}");
    await _listener.start(
      distanceFilterMeters: 20,
      accuracy: _accuracy,
    );
    _geofenceSubscription = _listener.events.listen((event) async {
      logger.notice("geofenceController:lat:${event.position.latitude.toString()}:lng:${event.position.longitude.toString()}");
      if (event.entering) {
        logger.notice("geofenceController:entering");
        final bool updateState = await _updateState();
        if (updateState) {
          final confirm = await _listener.onEnter(event);
          if (confirm) {
            await _saveState(DraftModeGeofenceStateEntity.stateEnter, true);
          }
        }
      } else {
        final confirmed = await _listener.onExit(event);
        if (confirmed) {
          await _saveState(DraftModeGeofenceStateEntity.stateExit, true);
          logger.notice("geofenceController:exit (confirmed)");
        } else {
          await _saveState(DraftModeGeofenceStateEntity.stateExit, false);
          logger.notice("geofenceController:exit (not confirmed)");
        }
      }
    });
  }

  /// Validates whether we can emit another enter event based on stored state.
  Future<bool> _updateState() async {
    final lastState = await _readState();
    return shouldStartTracking(
      lastState: lastState,
      expireUnapprovedMinutes: _expireUnapprovedMinutes,
    );
  }

  /// Persists the newest geofence state.
  Future<void> _saveState(String state, bool approved) async {
    logger.notice("geofenceController:saveState: state:$state, approved:$approved");
    await DraftModeGeofenceStateStorage().save(state, approved);
  }

  /// Loads the previously persisted geofence state, if any.
  Future<DraftModeGeofenceStateEntity?> _readState() async {
    final lastState = await DraftModeGeofenceStateStorage().read();
    if (lastState != null) {
      logger.notice("geofenceController:readState, lastEventDate: ${lastState.eventDate.toIso8601String()}, lastState: ${lastState.state}, lastApproved: ${lastState.approved}");
    } else {
      logger.notice("geofenceController:readState, no last state found");
    }
    return lastState;
  }

}
