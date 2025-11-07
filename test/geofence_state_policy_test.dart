import 'package:draftmode_geofence/geofence/state/entity.dart';
import 'package:draftmode_geofence/geofence/state/policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('shouldStartTracking', () {
    test('returns true when no prior state exists', () {
      expect(
        shouldStartTracking(lastState: null, expireUnapprovedMinutes: 2),
        isTrue,
      );
    });

    test('returns false when last state was enter', () {
      final lastState = DraftModeGeofenceStateEntity(
        eventDate: DateTime.now(),
        state: DraftModeGeofenceStateEntity.stateEnter,
      );

      expect(
        shouldStartTracking(
          lastState: lastState,
          expireUnapprovedMinutes: 2,
        ),
        isFalse,
      );
    });

    test('returns true when exit was approved', () {
      final lastState = DraftModeGeofenceStateEntity(
        eventDate: DateTime.now(),
        state: DraftModeGeofenceStateEntity.stateExit,
        approved: true,
      );

      expect(
        shouldStartTracking(
          lastState: lastState,
          expireUnapprovedMinutes: 2,
        ),
        isTrue,
      );
    });

    test('returns true when exit pending but expiry disabled', () {
      final lastState = DraftModeGeofenceStateEntity(
        eventDate: DateTime.now(),
        state: DraftModeGeofenceStateEntity.stateExit,
        approved: false,
      );

      expect(
        shouldStartTracking(lastState: lastState, expireUnapprovedMinutes: null),
        isTrue,
      );
    });

    test('returns false when exit pending and not expired', () {
      final lastState = DraftModeGeofenceStateEntity(
        eventDate: DateTime.now().subtract(const Duration(minutes: 1)),
        state: DraftModeGeofenceStateEntity.stateExit,
        approved: false,
      );

      expect(
        shouldStartTracking(
          lastState: lastState,
          expireUnapprovedMinutes: 5,
          now: DateTime.now(),
        ),
        isFalse,
      );
    });

    test('returns true when exit pending and expired', () {
      final referenceTime = DateTime.now();
      final lastState = DraftModeGeofenceStateEntity(
        eventDate: referenceTime.subtract(const Duration(minutes: 10)),
        state: DraftModeGeofenceStateEntity.stateExit,
        approved: false,
      );

      expect(
        shouldStartTracking(
          lastState: lastState,
          expireUnapprovedMinutes: 5,
          now: referenceTime,
        ),
        isTrue,
      );
    });

    test('falls back to system clock when now is omitted', () {
      final lastState = DraftModeGeofenceStateEntity(
        eventDate: DateTime.now().subtract(const Duration(minutes: 10)),
        state: DraftModeGeofenceStateEntity.stateExit,
        approved: false,
      );

      expect(
        shouldStartTracking(
          lastState: lastState,
          expireUnapprovedMinutes: 5,
        ),
        isTrue,
      );
    });
  });
}
