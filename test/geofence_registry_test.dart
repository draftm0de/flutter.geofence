import 'package:draftmode_geofence/geofence/listener.dart';
import 'package:draftmode_geofence/geofence/registry.dart';
import 'package:draftmode_geofence/geofence/state/entity.dart';
import 'package:draftmode_geofence/geofence/state/storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DraftModeGeofenceRegistry registry;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    registry = DraftModeGeofenceRegistry();
  });

  tearDown(() async {
    await registry.dispose();
  });

  test('registering multiple fences persists independent state', () async {
    final office = _TestListener();
    final home = _TestListener();

    await registry.registerFence(fenceId: 'office', listener: office);
    await registry.registerFence(fenceId: 'home', listener: home);

    office.emitEnter();
    home.emitExit();
    await Future<void>.delayed(Duration.zero);

    final officeState = await registry.readFenceState('office');
    final homeState = await registry.readFenceState('home');

    expect(officeState, isNotNull);
    expect(officeState!.state, DraftModeGeofenceStateEntity.stateEnter);
    expect(homeState, isNotNull);
    expect(homeState!.state, DraftModeGeofenceStateEntity.stateExit);
  });

  test('unregisterFence disposes controllers', () async {
    final listener = _TestListener();
    await registry.registerFence(fenceId: 'office', listener: listener);
    expect(registry.controllerFor('office'), isNotNull);

    await registry.unregisterFence('office');

    expect(registry.controllerFor('office'), isNull);
    expect(listener.stopCount, 1);
  });

  test('readFenceState falls back to persisted storage when no controller', () async {
    final offlineStorage = DraftModeGeofenceStateStorage(fenceId: 'ghost');
    await offlineStorage.save(
      DraftModeGeofenceStateEntity.stateEnter,
      true,
    );

    final state = await registry.readFenceState('ghost');
    expect(state, isNotNull);
    expect(state!.state, DraftModeGeofenceStateEntity.stateEnter);
  });

  test('registeredFenceIds mirrors current controllers', () async {
    await registry.registerFence(fenceId: 'office', listener: _TestListener());
    await registry.registerFence(fenceId: 'home', listener: _TestListener());

    expect(registry.registeredFenceIds, containsAll(['office', 'home']));

    await registry.unregisterFence('home');

    expect(registry.registeredFenceIds, contains('office'));
    expect(registry.registeredFenceIds.contains('home'), isFalse);
  });
}

class _TestListener extends DraftModeGeofenceListener {
  _TestListener()
      : stopCount = 0,
        super(
          centerLat: 0,
          centerLng: 0,
          radiusMeters: 10,
          onEvent: (_) async => true,
        );

  int stopCount;

  @override
  Future<void> start({
    int distanceFilterMeters = 15,
    LocationAccuracy accuracy = LocationAccuracy.best,
  }) async {}

  @override
  Future<void> stop() async {
    stopCount += 1;
  }

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
