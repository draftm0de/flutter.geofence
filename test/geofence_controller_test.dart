import 'package:draftmode_geofence/geofence/controller.dart';
import 'package:draftmode_geofence/geofence/listener.dart';
import 'package:draftmode_geofence/geofence/state/entity.dart';
import 'package:draftmode_geofence/geofence/state/storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<String> callLog;
  late TestDraftModeGeofenceListener listener;
  late DraftModeGeofenceController controller;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    callLog = [];
    listener = TestDraftModeGeofenceListener(
      onEnter: (_) async {
        callLog.add('enter');
        return true;
      },
      onExit: (_) async {
        callLog.add('exit');
        return true;
      },
    );
    controller = DraftModeGeofenceController(listener: listener);
  });

  tearDown(() async {
    await controller.dispose();
  });

  test('enter event triggers callback and persists state', () async {
    await controller.startGeofence();
    listener.emitEnter();
    await Future<void>.delayed(Duration.zero);

    expect(callLog, ['enter']);
    final stored = await DraftModeGeofenceStateStorage().read();
    expect(stored, isNotNull);
    expect(stored!.state, DraftModeGeofenceStateEntity.stateEnter);
    expect(stored.approved, isTrue);
  });

  test('enter ignored when last state was enter', () async {
    await DraftModeGeofenceStateStorage()
        .save(DraftModeGeofenceStateEntity.stateEnter, true);

    await controller.startGeofence();
    listener.emitEnter();
    await Future<void>.delayed(Duration.zero);

    expect(callLog, isEmpty);
  });

  test('exit without notifier auto-confirms and persists approval', () async {
    await controller.startGeofence();
    listener.emitExit();
    await Future<void>.delayed(Duration.zero);

    expect(callLog, ['exit']);
    final stored = await DraftModeGeofenceStateStorage().read();
    expect(stored, isNotNull);
    expect(stored!.state, DraftModeGeofenceStateEntity.stateExit);
    expect(stored.approved, isTrue);
  });

  test('exit with notifier requires confirmation (not granted)', () async {
    listener = TestDraftModeGeofenceListener(
      onEnter: (_) async {
        callLog.add('enter');
        return true;
      },
      onExit: (_) async {
        callLog.add('exit_attempt');
        return false;
      },
    );
    controller = DraftModeGeofenceController(listener: listener);

    await controller.startGeofence();
    listener.emitExit();
    await Future<void>.delayed(Duration.zero);

    expect(callLog, ['exit_attempt']);
    final stored = await DraftModeGeofenceStateStorage().read();
    expect(stored, isNotNull);
    expect(stored!.state, DraftModeGeofenceStateEntity.stateExit);
    expect(stored.approved, isFalse);
  });
}

class TestDraftModeGeofenceListener extends DraftModeGeofenceListener {
  TestDraftModeGeofenceListener({
    required Future<bool> Function(DraftModeGeofenceEvent event) onEnter,
    required Future<bool> Function(DraftModeGeofenceEvent event) onExit,
    DraftModeGeofenceNotifier? notifier,
  }) : super(
          centerLat: 0,
          centerLng: 0,
          radiusMeters: 5,
          onEnter: onEnter,
          onExit: onExit,
        );

  @override
  Future<void> start({
    int distanceFilterMeters = 15,
    LocationAccuracy accuracy = LocationAccuracy.best,
  }) async {}

  @override
  Future<void> stop() async {}

  void emitEnter() {
    emitTestEvent(DraftModeGeofenceEvent.enter(_position()));
  }

  void emitExit() {
    emitTestEvent(DraftModeGeofenceEvent.exit(_position()));
  }

  Position _position() => Position(
        latitude: 0,
        longitude: 0,
        timestamp: DateTime.now(),
        accuracy: 1,
        altitude: 0,
        altitudeAccuracy: 0,
        heading: 0,
        headingAccuracy: 0,
        speed: 0,
        speedAccuracy: 0,
      );
}
