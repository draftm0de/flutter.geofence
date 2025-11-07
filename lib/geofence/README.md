# DraftMode Geofence

Lightweight building blocks for adding a single circular geofence to a Flutter
app. The module is split into a `DraftModeGeofenceListener` (produces enter/exit
stream events), a `DraftModeGeofenceController` (persists state + orchestrates
callbacks), and optional UI helpers (`DraftModeGeofenceNotifier` and
`DraftModeGeofenceConfirm`).

## Typical Flow

1. Instantiate a `DraftModeGeofenceListener` with the center point, radius, and
   async callbacks for `onEnter`/`onExit`. Pass an optional notifier when you
   need confirmation before leaving the fence.
2. Create a `DraftModeGeofenceController` with that listener and call
   `startGeofence()` once the app is ready. The controller automatically stores
   the last event via `DraftModeGeofenceStateStorage` so duplicate enter/exit
   sequences can be avoided.
3. On teardown call `dispose()` on the controller to stop location updates.

## Testing

Unit tests live under `test/` and can be executed with `flutter test`. The
included suite covers controller orchestration, listener behavior, persistence,
and the restart policy (see the `test/` folder).

### Coverage

1. `flutter test --coverage`
2. `genhtml coverage/lcov.info -o coverage/html`
3. Open `coverage/html/index.html` in a browser for the detailed report (the
   current suite reaches 100% line coverage).
