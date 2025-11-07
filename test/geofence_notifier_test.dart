import 'package:draftmode_geofence/geofence/listener.dart';
import 'package:draftmode_geofence/geofence/notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';

DraftModeGeofenceEvent _event() {
  final position = Position(
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
  return DraftModeGeofenceEvent.exit(position);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('confirmMovement auto-approves when dialog cannot be shown',
      (tester) async {
    final notifier = DraftModeGeofenceNotifier(
      navigatorKey: GlobalKey<NavigatorState>(),
      isAppInForeground: () => false,
      isMounted: () => true,
    );

    final result = await notifier.confirmMovement(
      _event(),
      title: 'Confirm exit',
      message: 'Leave the fence?',
    );

    expect(result, isTrue);
  });

  testWidgets('confirmMovement surfaces dialog choice when foreground',
      (tester) async {
    final navigatorKey = GlobalKey<NavigatorState>();
    await tester.pumpWidget(MaterialApp(
      navigatorKey: navigatorKey,
      home: const SizedBox.shrink(),
    ));

    final notifier = DraftModeGeofenceNotifier(
      navigatorKey: navigatorKey,
      isAppInForeground: () => true,
      isMounted: () => true,
    );

    final confirmFuture = notifier.confirmMovement(
      _event(),
      title: 'Confirm exit',
      message: 'Leave the fence?',
    );

    await tester.pumpAndSettle();
    expect(find.text('Confirm exit'), findsOneWidget);

    await tester.tap(find.text('Yes'));
    await tester.pumpAndSettle();

    expect(await confirmFuture, isTrue);
  });
}
