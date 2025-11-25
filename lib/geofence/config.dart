import 'listener.dart';

abstract class DraftModeGeofenceConfig {
  String get id;
  String get label;
  double get lat;
  double get lng;
  double get radiusMeters;
  Future<bool> Function(DraftModeGeofenceEvent event)? get onEvent;
}
