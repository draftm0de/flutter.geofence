# DraftMode Geofence

Lightweight building blocks for adding a single circular geofence to a Flutter
app. The module is split into a `DraftModeGeofenceListener` (produces enter/exit
stream events), a `DraftModeGeofenceController` (persists state + orchestrates
callbacks), and an optional UI helper (`DraftModeGeofenceNotifier`) for showing
movement confirmations.

## Typical Flow

1. Instantiate a `DraftModeGeofenceListener` with the center point, radius, and
   async callbacks for `onEnter`/`onExit`. Each callback must resolve to `true`
   when the transition is approved (for example after showing a dialog). Pass
   an optional notifier when you need confirmation before leaving the fence.
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

## UI confirmations

Apps that need to surface a platform-aware confirmation dialog can wire the
optional `DraftModeGeofenceNotifier`. The notifier depends on the shared
`draftmode_ui` package and uses `DraftModeUIConfirm` under the hood. When the
app is backgrounded (or no navigator context is available) the notifier
auto-approves the movement so the controller can keep running. When foreground,
the dialog result is forwarded to the listener callback so the controller knows
whether the exit/enter transition should be persisted as approved or pending.
You can pass localized `confirmLabel`/`cancelLabel` strings to
`confirmMovement` so the dialog buttons match the surrounding UI language.
