import 'package:draftmode_geofence/geofence/listener.dart';
import 'package:draftmode_geofence/geofence/notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';

DraftModeGeofenceEvent _exitEvent() {
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

  test('confirmMovement auto-approves when dialog cannot be shown', () async {
    final notifier = DraftModeGeofenceNotifier(
      navigatorKey: GlobalKey<NavigatorState>(),
      isAppInForeground: () => false,
      isMounted: () => true,
    );

    final result = await notifier.confirmMovement(
      _exitEvent(),
      title: 'Confirm exit',
      message: 'Leave geofence?',
    );

    expect(result, isTrue);
  });

  testWidgets('confirmMovement uses dialog result when foreground', (tester) async {
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
      _exitEvent(),
      title: 'Confirm exit',
      message: 'Leave geofence?',
      confirmLabel: 'Allow',
      cancelLabel: 'Stay',
    );

    await tester.pumpAndSettle();
    expect(find.text('Confirm exit'), findsOneWidget);
    expect(find.text('Allow'), findsOneWidget);
    expect(find.text('Stay'), findsOneWidget);

    await tester.tap(find.text('Allow'));
    await tester.pumpAndSettle();

    expect(await confirmFuture, isTrue);
  });
}
