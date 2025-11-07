/// Represents the last persisted geofence event.
class DraftModeGeofenceStateEntity {
  static const String stateEnter = 'enter';
  static const String stateExit = 'exit';

  final DateTime eventDate;
  final String state;
  final bool approved;

  DraftModeGeofenceStateEntity({
    required this.eventDate,
    required this.state,
    this.approved = true,
  });
}
