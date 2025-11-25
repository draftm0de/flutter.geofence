## Geofence Sample

The `example/` app demonstrates how DraftMode's notifier + geofence plugins can
coordinate fence registration, Apple Maps previews, and local notifications.
When adding or editing a fence, the left-hand form keeps the identifier locked
for existing entries while latitude/longitude/radius can be tweaked freely. The
embedded Apple Map mirrors those coordinates on iOS simulators/devices.

### iOS setup

Add the standard location permissions to `ios/Runner/Info.plist`:

```
<key>NSLocationWhenInUseUsageDescription</key>
<string>This app needs access to your location.</string>
<key>NSLocationAlwaysUsageDescription</key>
<string>This app needs location access to track your position.</string>
```

Because the inline map uses `apple_maps_flutter`, no Google Maps key is
required. Non‑iOS builds simply render a short placeholder message in the map
section.

### Testing & coverage

The repo targets 100% coverage where practical (UI widgets that proxy platform
views are excluded). Run analyzer + tests from the repository root:

```
flutter test --coverage
genhtml coverage/lcov.info --output-directory coverage/html
```

The `coverage/html/index.html` report can be opened locally to inspect gaps.
