# DraftMode Geofence Example

This sample wires up the `draftmode_geofence` package with multiple circular
regions. Each fence registers its own `DraftModeGeofenceListener` and is managed
through the new `DraftModeGeofenceRegistry` so enter/exit events and persisted
state stay isolated.

## Running the demo

1. `cd example`
2. `flutter pub get`
3. `flutter run`

The home screen lists every registered fence, shows the latest in-memory state
(inside/outside), and exposes buttons to refresh the persisted snapshot, add a
new geofence, or reset back to the default coordinates.

## Customizing fences

Fence definitions live in `lib/entity/config.dart`. Update the default list or
persisted JSON payload to point at your own coordinates/radii, then tap **Reset
sample fences** in the app or use the **Add geofence** button to create new
regions without restarting.
