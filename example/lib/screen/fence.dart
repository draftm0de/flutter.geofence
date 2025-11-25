import 'dart:io' show Platform;

import 'package:draftmode_notifier_example/entity/config.dart';
import 'package:draftmode_ui/buttons.dart';
import 'package:draftmode_ui/components.dart';
import 'package:draftmode_ui/pages.dart';
import 'package:flutter/cupertino.dart';
import 'package:apple_maps_flutter/apple_maps_flutter.dart';

/// Presents the details for a single [GeofenceConfig] and lets the user edit
/// or delete it.
class FenceScreen extends StatefulWidget {
  const FenceScreen({
    required this.config,
    this.onSave,
    this.onDelete,
    super.key,
  });

  final GeofenceConfig config;
  final Future<void> Function(GeofenceConfig updated)? onSave;
  final Future<void> Function(String id)? onDelete;

  @override
  State<FenceScreen> createState() => _FenceScreenState();
}

class _FenceScreenState extends State<FenceScreen> {
  late final TextEditingController _idController;
  late final TextEditingController _labelController;
  late final TextEditingController _latController;
  late final TextEditingController _lngController;
  late final TextEditingController _radiusController;

  String? _error;
  bool _isSaving = false;
  late LatLng _mapPosition;
  bool _hasValidPosition = false;
  AppleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    _idController = TextEditingController(text: widget.config.id);
    _labelController = TextEditingController(text: widget.config.label);
    _latController = TextEditingController(text: widget.config.lat.toString());
    _lngController = TextEditingController(text: widget.config.lng.toString());
    _radiusController = TextEditingController(
      text: widget.config.radiusMeters.toStringAsFixed(0),
    );
    _mapPosition = LatLng(widget.config.lat, widget.config.lng);
    _hasValidPosition = widget.config.lat != 0 || widget.config.lng != 0;
    if (!_hasValidPosition) {
      _mapPosition = const LatLng(48.198841, 16.394724);
    }
  }

  @override
  void dispose() {
    _idController.dispose();
    _labelController.dispose();
    _latController.dispose();
    _lngController.dispose();
    _radiusController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isNewFence = widget.config.id.isEmpty;
    return DraftModeUIPage(
      navigationTitle: 'Geofence (Setting)',
      topLeading: null,
      topTrailing: [
        DraftModePageNavigationTopItem(
          icon: DraftModeUIButtons.save,
          loadWidget: _isSaving ? const CupertinoActivityIndicator() : null,
          onTap: (widget.onSave == null || _isSaving)
              ? null
              : () async => _handleSave(),
        ),
      ],
      bottomTrailing: (widget.onDelete == null)
          ? null
          : [
              DraftModePageNavigationBottomItem(
                icon: DraftModeUIButtons.trash,
                onTap: _isSaving ? null : _confirmDelete,
              ),
            ],
      body: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DraftModeUISection(
            children: [
              _buildField(
                label: 'Identifier',
                controller: _idController,
                enabled: isNewFence,
              ),
              _buildField(
                label: 'Label',
                controller: _labelController,
              ),
              _buildField(
                label: 'Latitude',
                controller: _latController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                onChanged: (_) => _handleLatLngChanged(),
              ),
              _buildField(
                label: 'Longitude',
                controller: _lngController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                onChanged: (_) => _handleLatLngChanged(),
              ),
              _buildField(
                label: 'Radius (m)',
                controller: _radiusController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8, left: 16, right: 16),
                  child: Text(
                    _error!,
                    style: const TextStyle(
                      color: CupertinoColors.systemRed,
                      fontSize: 13,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          DraftModeUISection(
            children: [
              _buildMap(),
            ]
          ),
        ],
      ),
    );
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    bool enabled = true,
    TextInputType keyboardType = TextInputType.text,
    ValueChanged<String>? onChanged,
  }) {
    const double labelWidth = 110;
    return DraftModeUIRow(
      Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: labelWidth,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: CupertinoColors.secondaryLabel,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: CupertinoTextField(
              controller: controller,
              enabled: enabled,
              keyboardType: keyboardType,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  /// Shows an Apple Map preview (or a placeholder when not on iOS).
  Widget _buildMap() {
    if (!Platform.isIOS) {
      return DraftModeUIRow(
        Container(
          alignment: Alignment.centerLeft,
          child: const Text(
            'Apple Maps preview available on iOS simulators/devices only.',
          ),
        ),
      );
    }
    final annotation = Annotation(
      annotationId: AnnotationId('fence'),
      position: _mapPosition,
    );
    final cameraPosition = CameraPosition(
      target: _mapPosition,
      zoom: _hasValidPosition ? 15 : 3,
    );
    return SizedBox(
      height: 320,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: AppleMap(
          initialCameraPosition: cameraPosition,
          annotations: {annotation},
          onMapCreated: (controller) => _mapController = controller,
          onTap: _handleMapTap,
          rotateGesturesEnabled: false,
        ),
      ),
    );
  }

  Future<void> _handleSave() async {
    final onSave = widget.onSave;
    if (onSave == null) return;
    final bool isNewFence = widget.config.id.isEmpty;
    final label = _labelController.text.trim();
    final lat = double.tryParse(_latController.text);
    final lng = double.tryParse(_lngController.text);
    final radius = double.tryParse(_radiusController.text);
    final enteredId = _idController.text.trim();
    if (label.isEmpty || lat == null || lng == null || radius == null) {
      setState(() {
        _error = 'Enter label, latitude/longitude, and radius.';
      });
      return;
    }
    setState(() {
      _error = null;
      _isSaving = true;
    });
    try {
      await onSave(
        widget.config.copyWith(
          id: isNewFence && enteredId.isNotEmpty ? enteredId : widget.config.id,
          label: label,
          lat: lat,
          lng: lng,
          radiusMeters: radius,
        ),
      );
      if (!mounted) return;
      Navigator.of(context).pop();
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _confirmDelete() async {
    final onDelete = widget.onDelete;
    if (onDelete == null) return;
    final shouldDelete = await DraftModeUIShowDialog().show(
      title: 'Delete geofence',
      message: 'Remove "${widget.config.label}"? This action cannot be undone.'
    );
    if (shouldDelete == true) {
      await onDelete(widget.config.id);
      if (!mounted) return;
      Navigator.of(context).pop();
    }
  }

  void _handleLatLngChanged() {
    final lat = double.tryParse(_latController.text);
    final lng = double.tryParse(_lngController.text);
    if (lat == null || lng == null) {
      return;
    }
    final target = LatLng(lat, lng);
    setState(() {
      _mapPosition = target;
      _hasValidPosition = true;
    });
    _mapController?.animateCamera(CameraUpdate.newLatLng(target));
  }

  void _handleMapTap(LatLng position) {
    setState(() {
      _mapPosition = position;
      _hasValidPosition = true;
      _latController.text = position.latitude.toStringAsFixed(6);
      _lngController.text = position.longitude.toStringAsFixed(6);
    });
  }
}
