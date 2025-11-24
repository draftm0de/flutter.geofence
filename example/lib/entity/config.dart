import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class GeofenceConfig {
  const GeofenceConfig({
    required this.id,
    required this.label,
    required this.lat,
    required this.lng,
    this.radiusMeters = 120,
  });

  final String id;
  final String label;
  final double lat;
  final double lng;
  final double radiusMeters;

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
  }) =>
      GeofenceConfig(
        id: id ?? this.id,
        label: label ?? this.label,
        lat: lat ?? this.lat,
        lng: lng ?? this.lng,
        radiusMeters: radiusMeters ?? this.radiusMeters,
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
