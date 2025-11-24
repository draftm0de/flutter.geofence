import 'package:draftmode_geofence/geofence/state/entity.dart';
import 'package:draftmode_geofence/geofence/state/storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late DraftModeGeofenceStateStorage storage;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    storage = DraftModeGeofenceStateStorage();
  });

  test('read returns null when nothing was persisted', () async {
    final result = await storage.read();
    expect(result, isNull);
  });

  test('save persists state and read restores it', () async {
    final saved = await storage.save(
      DraftModeGeofenceStateEntity.stateEnter,
      true,
    );
    expect(saved, isTrue);

    final restored = await storage.read();
    expect(restored, isNotNull);
    expect(restored!.state, DraftModeGeofenceStateEntity.stateEnter);
    expect(restored.approved, isTrue);
  });

  test('read captures approval flag changes', () async {
    await storage.save(DraftModeGeofenceStateEntity.stateExit, false);
    final restored = await storage.read();
    expect(restored, isNotNull);
    expect(restored!.state, DraftModeGeofenceStateEntity.stateExit);
    expect(restored.approved, isFalse);
  });

  test('separate fence ids do not override each other', () async {
    final officeStorage = DraftModeGeofenceStateStorage(fenceId: 'office');
    final homeStorage = DraftModeGeofenceStateStorage(fenceId: 'home');

    await officeStorage.save(DraftModeGeofenceStateEntity.stateEnter, true);
    await homeStorage.save(DraftModeGeofenceStateEntity.stateExit, false);

    final officeState = await officeStorage.read();
    final homeState = await homeStorage.read();
    final defaultState = await storage.read();

    expect(officeState, isNotNull);
    expect(officeState!.state, DraftModeGeofenceStateEntity.stateEnter);
    expect(homeState, isNotNull);
    expect(homeState!.state, DraftModeGeofenceStateEntity.stateExit);
    expect(defaultState, isNull);
  });
}
