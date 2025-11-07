import 'package:draftmode_geofence/geofence/confirm.dart';
import 'package:draftmode_geofence/geofence/notifier.dart';
import 'package:draftmode_geofence/geofence/state/entity.dart';
import 'package:draftmode_geofence/geofence/state/policy.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  DraftModeGeofenceNotifier buildNotifier({int expireMinutes = 2}) {
    return DraftModeGeofenceNotifier(
      navigatorKey: GlobalKey<NavigatorState>(),
      isAppInForeground: () => true,
      isMounted: () => true,
      confirmDialog: DraftModeGeofenceConfirm(
        title: 'Confirm exit',
        message: 'Leave geofence?',
      ),
      expireStateMinutes: expireMinutes,
    );
  }

  group('shouldStartTracking', () {
    test('returns true when no prior state exists', () {
      expect(
        shouldStartTracking(lastState: null, notifier: buildNotifier()),
        isTrue,
      );
    });

    test('returns false when last state was enter', () {
      final lastState = DraftModeGeofenceStateEntity(
        eventDate: DateTime.now(),
        state: DraftModeGeofenceStateEntity.stateEnter,
      );

      expect(
        shouldStartTracking(lastState: lastState, notifier: buildNotifier()),
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
        shouldStartTracking(lastState: lastState, notifier: buildNotifier()),
        isTrue,
      );
    });

    test('returns true when exit pending but notifier missing', () {
      final lastState = DraftModeGeofenceStateEntity(
        eventDate: DateTime.now(),
        state: DraftModeGeofenceStateEntity.stateExit,
        approved: false,
      );

      expect(
        shouldStartTracking(lastState: lastState, notifier: null),
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
          notifier: buildNotifier(expireMinutes: 5),
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
          notifier: buildNotifier(expireMinutes: 5),
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
          notifier: buildNotifier(expireMinutes: 5),
        ),
        isTrue,
      );
    });
  });
}
