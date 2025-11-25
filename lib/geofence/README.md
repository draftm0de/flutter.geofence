# DraftMode Geofence

Lightweight building blocks for adding one or many circular geofences to a Flutter
app. The module is split into a `DraftModeGeofenceListener` (produces enter/exit
stream events) and a `DraftModeGeofenceController` (persists state + orchestrates
callbacks). UI confirmations/notifications are left to the integrating app so
they can be tailored per product.

## Typical Flow

1. Instantiate a `DraftModeGeofenceListener` with the center point, radius, and
   async `onEvent`. The provided callback fires for both enter/exit events
   (inspect `event.entering`) and must resolve to `true` when the movement is
   approved (for example after showing a dialog).
2. Create a `DraftModeGeofenceController` with that listener and call
   `startGeofence()` once the app is ready. The controller automatically stores
   the last event via `DraftModeGeofenceStateStorage` so duplicate enter/exit
   sequences can be avoided.
3. On teardown call `dispose()` on the controller to stop location updates.

## Multiple fences

Use `DraftModeGeofenceRegistry` when several listeners need to run in parallel.
Each fence is registered under an identifier so its persisted state does not
collide with others:

```
final registry = DraftModeGeofenceRegistry();
for (final region in regions) {
  final listener = DraftModeGeofenceListener(
    centerLat: region.lat,
    centerLng: region.lng,
    radiusMeters: region.radiusMeters,
    onEvent: (event) => handleRegionEvent(region.id, event),
  );
  await registry.registerFence(fenceId: region.id, listener: listener);
}

final officeState = await registry.readFenceState('office');
// ...later, dispose every fence at once
await registry.dispose();
```

`DraftModeGeofenceStateStorage` now namespaces entries by fence id, so existing
single-fence integrations keep working while multi-fence setups retain their own
history.

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

If you need dialogs or notifications before approving a transition, hook that up
inside your app (see the example project for reference). The controller only
expects the provided callbacks to resolve `true`/`false` based on the result of
your UI flow.
