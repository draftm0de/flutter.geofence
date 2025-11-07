import 'entity.dart';

/// Shared logic that decides if a new tracking cycle should start after reading
/// the last persisted geofence state.
bool shouldStartTracking({
  required DraftModeGeofenceStateEntity? lastState,
  required int? expireUnapprovedMinutes,
  DateTime? now,
}) {
  if (lastState == null) return true;

  if (lastState.state == DraftModeGeofenceStateEntity.stateEnter) {
    return false;
  }

  if (lastState.approved) return true;

  if (expireUnapprovedMinutes == null) return true;

  final referenceTime = now ?? DateTime.now();
  final diffMinutes = referenceTime.difference(lastState.eventDate).inMinutes;
  return diffMinutes > expireUnapprovedMinutes;
}