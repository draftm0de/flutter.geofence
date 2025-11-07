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
app is foregrounded, the dialog result determines whether the listener callback
should proceed. When a dialog cannot be shown (for example because the app is
backgrounded or the navigator key is missing) the notifier now posts an
actionable local notification instead of auto-approving the movement.

Call `DraftModeGeofenceBackgroundNotifier.instance.init(...)` during app
bootstrap with an `onConfirm` callback to register Android channels + iOS
categories and to handle YES/NO actions from background notifications. Pass the
same callback to `DraftModeGeofenceNotifier.confirmMovement` so it is invoked
whenever the user approves either from the dialog or from the notification.
Localized `confirmLabel`/`cancelLabel` strings are still supported so the UI
matches the surrounding language.
