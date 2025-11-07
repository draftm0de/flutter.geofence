import 'dart:async';

import 'package:draftmode_geofence/geofence/listener.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geolocator_platform_interface/geolocator_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeGeolocatorPlatform fakePlatform;
  late DraftModeGeofenceListener listener;

  setUp(() {
    fakePlatform = FakeGeolocatorPlatform();
    GeolocatorPlatform.instance = fakePlatform;
    listener = DraftModeGeofenceListener(
      centerLat: 0,
      centerLng: 0,
      radiusMeters: 10,
      onEnter: (_) async => true,
      onExit: (_) async => true,
    );
  });

  tearDown(() async {
    await listener.stop();
    fakePlatform.dispose();
  });

  test('emits exit and enter events when crossing radius', () async {
    final results = listener.events
        .map((event) => event.entering ? 'enter' : 'exit')
        .take(2)
        .toList();

    await listener.start();

    fakePlatform.emitPosition(latitude: 0.001, longitude: 0); // exit
    fakePlatform.emitPosition(latitude: 0.0, longitude: 0); // enter

    expect(await results, ['exit', 'enter']);
  });

  test('resetting inside state suppresses first emitted event', () async {
    var emitted = false;
    final sub = listener.events.listen((_) {
      emitted = true;
    });

    await listener.start();
    listener.resetInsideState();
    fakePlatform.emitPosition(latitude: 0.002, longitude: 0);
    await Future<void>.delayed(Duration.zero);

    expect(emitted, isFalse);
    await sub.cancel();
  });

  test('start throws when services disabled', () async {
    fakePlatform.serviceEnabled = false;
    await expectLater(
      () => listener.start(),
      throwsA(
        isA<Exception>().having(
          (ex) => ex.toString(),
          'message',
          contains('Location services disabled'),
        ),
      ),
    );
  });

  test('start throws when permission denied after request', () async {
    fakePlatform.permissionStatus = LocationPermission.denied;
    fakePlatform.requestResult = LocationPermission.denied;
    await expectLater(
      () => listener.start(),
      throwsA(
        isA<Exception>().having(
          (ex) => ex.toString(),
          'message',
          contains('Location permission denied'),
        ),
      ),
    );
  });

  test('start throws when permission denied forever', () async {
    fakePlatform.permissionStatus = LocationPermission.deniedForever;
    await expectLater(
      () => listener.start(),
      throwsA(
        isA<Exception>().having(
          (ex) => ex.toString(),
          'message',
          contains('Location permission denied'),
        ),
      ),
    );
  });
}

class FakeGeolocatorPlatform extends GeolocatorPlatform {
  FakeGeolocatorPlatform();

  bool serviceEnabled = true;
  LocationPermission permissionStatus = LocationPermission.always;
  LocationPermission requestResult = LocationPermission.always;
  Position currentPosition = Position(
    latitude: 0,
    longitude: 0,
    timestamp: DateTime.fromMillisecondsSinceEpoch(0),
    accuracy: 1,
    altitude: 0,
    altitudeAccuracy: 0,
    heading: 0,
    headingAccuracy: 0,
    speed: 0,
    speedAccuracy: 0,
  );

  final _controller = StreamController<Position>.broadcast();

  void emitPosition({required double latitude, required double longitude}) {
    final position = Position(
      latitude: latitude,
      longitude: longitude,
      timestamp: DateTime.now(),
      accuracy: 1,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
    );
    _controller.add(position);
  }

  void dispose() {
    _controller.close();
  }

  @override
  Future<bool> isLocationServiceEnabled() async => serviceEnabled;

  @override
  Future<LocationPermission> checkPermission() async => permissionStatus;

  @override
  Future<LocationPermission> requestPermission() async => requestResult;

  @override
  Future<Position> getCurrentPosition({
    LocationSettings? locationSettings,
  }) async => currentPosition;

  @override
  Stream<Position> getPositionStream({LocationSettings? locationSettings}) =>
      _controller.stream;
}
