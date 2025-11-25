import 'dart:convert';

import 'package:draftmode_geofence/geofence.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GeofenceConfig implements DraftModeGeofenceConfig {
  const GeofenceConfig(
      {required this.id,
      required this.label,
      required this.lat,
      required this.lng,
      this.radiusMeters = 120,
      this.onEvent});

  @override
  final String id;
  @override
  final String label;
  @override
  final double lat;
  @override
  final double lng;
  @override
  final double radiusMeters;
  @override
  final Future<bool> Function(DraftModeGeofenceEvent event)? onEvent;

  static const List<GeofenceConfig> defaults = [
    GeofenceConfig(
      id: 'office',
      label: 'Office HQ',
      lat: 48.198841,
      lng: 16.394724,
      radiusMeters: 120,
    ),
    GeofenceConfig(
      id: 'coffee',
      label: 'Coffee Shop',
      lat: 48.199515,
      lng: 16.39635,
      radiusMeters: 90,
    ),
  ];

  GeofenceConfig copyWith({
    String? id,
    String? label,
    double? lat,
    double? lng,
    double? radiusMeters,
    Future<bool> Function(DraftModeGeofenceEvent event)? onEvent,
  }) =>
      GeofenceConfig(
        id: id ?? this.id,
        label: label ?? this.label,
        lat: lat ?? this.lat,
        lng: lng ?? this.lng,
        radiusMeters: radiusMeters ?? this.radiusMeters,
        onEvent: onEvent ?? this.onEvent,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'lat': lat,
        'lng': lng,
        'radiusMeters': radiusMeters,
      };

  factory GeofenceConfig.fromJson(Map<String, dynamic> data) => GeofenceConfig(
        id: data['id'] as String,
        label: data['label'] as String,
        lat: (data['lat'] as num).toDouble(),
        lng: (data['lng'] as num).toDouble(),
        radiusMeters: (data['radiusMeters'] as num).toDouble(),
      );
}

class GeofenceConfigStore {
  static const _storageKey = 'DraftModeSampleGeofences';

  Future<List<GeofenceConfig>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_storageKey);
    if (stored == null) {
      return GeofenceConfig.defaults;
    }
    try {
      final List<dynamic> decoded = jsonDecode(stored) as List<dynamic>;
      final configs = decoded
          .whereType<Map<String, dynamic>>()
          .map(GeofenceConfig.fromJson)
          .toList();
      if (configs.isEmpty) {
        return GeofenceConfig.defaults;
      }
      return configs;
    } catch (_) {
      return GeofenceConfig.defaults;
    }
  }

  Future<void> saveAll(List<GeofenceConfig> configs) async {
    final prefs = await SharedPreferences.getInstance();
    final data = configs.map((config) => config.toJson()).toList();
    await prefs.setString(_storageKey, jsonEncode(data));
  }

  Future<void> resetToDefaults() async {
    await saveAll(GeofenceConfig.defaults);
  }
}
