import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'entity.dart';

/// Thin wrapper around [SharedPreferences] for storing the last geofence state.
class DraftModeGeofenceStateStorage {
  static const String _storageKeyBase = 'DraftModeGeofenceState';
  static const String defaultFenceId = 'default';
  static const String _keyEventDate = 'eventDate';
  static const String _keyState = 'state';
  static const String _keyApproved = 'approved';

  DraftModeGeofenceStateStorage({String? fenceId})
      : fenceId = fenceId ?? defaultFenceId;

  final String fenceId;

  Future<SharedPreferences> _prefs() => SharedPreferences.getInstance();

  String get _storageKey => fenceId == defaultFenceId
      ? _storageKeyBase
      : '$_storageKeyBase::$fenceId';

  /// Reads the serialized state from shared preferences.
  Future<DraftModeGeofenceStateEntity?> read() async {
    final prefs = await _prefs();
    final data = prefs.getString(_storageKey);
    if (data != null) {
      final jsonData = jsonDecode(data);
      return DraftModeGeofenceStateEntity(
        eventDate: DateTime.tryParse(jsonData[_keyEventDate]) as DateTime,
        state: jsonData[_keyState],
        approved: (jsonData[_keyApproved] == 'true'),
      );
    }
    return null;
  }

  /// Writes the latest state snapshot to shared preferences.
  Future<bool> save(String state, bool approved) async {
    final data = {
      _keyEventDate: DateTime.now().toIso8601String(),
      _keyState: state,
      _keyApproved: approved ? 'true' : 'false',
    };
    final prefs = await _prefs();
    return await prefs.setString(_storageKey, jsonEncode(data));
  }
}
