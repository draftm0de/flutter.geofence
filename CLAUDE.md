# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Development Commands

### Testing
```bash
# Run all tests
flutter test

# Run a single test file
flutter test test/geofence_controller_test.dart

# Generate coverage report
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
# Open coverage/html/index.html in browser
```

### Code Quality
```bash
# Format code (only after tests pass)
dart format --output=write .

# Analyze code (must pass with zero warnings)
dart analyze
flutter analyze
```

### Dependency Management
```bash
# Update dependencies
./flutter.update.sh
```

## Architecture Overview

This is a Flutter geofencing package providing location-based enter/exit notifications.

### Core Components

- **DraftModeGeofenceController** (`lib/geofence/controller.dart`): Orchestrates the geofence lifecycle, manages state persistence, and coordinates callbacks
- **DraftModeGeofenceListener** (`lib/geofence/listener.dart`): Produces enter/exit stream events by monitoring device location against a circular fence
- **DraftModeGeofenceNotifier** (`lib/geofence/notifier.dart`): UI helper for showing movement confirmations via dialogs or notifications
- **DraftModeGeofenceBackgroundNotifier** (`lib/geofence/notifier/background.dart`): Handles background notifications when app is not in foreground

### State Management

Located in `lib/geofence/state/`:
- **entity.dart**: Defines `DraftModeGeofenceEvent` and state entities
- **policy.dart**: Determines when to restart tracking based on grace periods
- **storage.dart**: Persists the last approved/pending event using `shared_preferences`

### Dependencies

- `geolocator`: Location tracking
- `flutter_local_notifications`: Background notifications
- `draftmode_ui`: Sibling package at `../ui` for platform-aware dialogs
- `shared_preferences`: State persistence

## Workflow Requirements

- **Branch policy**: Never commit directly to `main`. Create a feature branch before making changes.
- **Pre-approval**: `dart format`, `dart analyze`, and `flutter test` commands are always permitted without additional approval.
- **Testing**: Strive for 100% code coverage (aspirational target). Tests are colocated under `test/`.
- **Format order**: Run `dart format` only after `dart analyze` and tests succeed, then rerun tests to confirm nothing regressed.
- **Module READMEs**: `lib/geofence/README.md` documents the public API—update when functionality changes.