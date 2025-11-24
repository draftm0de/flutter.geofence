import 'package:draftmode_geofence/geofence.dart';
import 'package:draftmode_notifier_example/entity/config.dart';
import 'package:draftmode_ui/components.dart';
import 'package:draftmode_ui/pages.dart';
import 'package:flutter/cupertino.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    required this.configs,
    required this.liveStates,
    required this.persistedStates,
    this.isLoading = false,
    this.onRefreshStates,
    this.onResetGeofences,
    this.onAddFence,
    this.onDeleteFence,
    super.key,
  });

  final List<GeofenceConfig> configs;
  final Map<String, bool> liveStates;
  final Map<String, DraftModeGeofenceStateEntity?> persistedStates;
  final bool isLoading;
  final Future<void> Function()? onRefreshStates;
  final Future<void> Function()? onResetGeofences;
  final Future<void> Function({
    required String label,
    required double latitude,
    required double longitude,
    required double radiusMeters,
  })? onAddFence;
  final Future<void> Function(String id)? onDeleteFence;

  @override
  Widget build(BuildContext context) {
    return DraftModeUIPageExample(
      title: 'Geofence Demo',
      children: [
        DraftModeUISection(
          header: 'Active geofences',
          children: [
            if (isLoading)
              const DraftModeUIRow(
                Center(child: CupertinoActivityIndicator()),
              )
            else if (configs.isEmpty)
              DraftModeUIRow(_buildEmptyState(context))
            else
              ...configs.map((config) => _buildFenceRow(context, config)),
            DraftModeUIRow(
              SizedBox(
                width: double.infinity,
                child: CupertinoButton.filled(
                  onPressed: onAddFence == null
                      ? null
                      : () => _showAddFenceDialog(context),
                  child: const Text('Add geofence'),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        DraftModeUISection(
          children: [
            SizedBox(
              width: double.infinity,
              child: CupertinoButton.filled(
                onPressed: onRefreshStates == null
                    ? null
                    : () {
                        onRefreshStates!.call();
                      },
                child: const Text('Refresh persisted state'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: CupertinoButton(
                onPressed: onResetGeofences == null
                    ? null
                    : () {
                        onResetGeofences!.call();
                      },
                child: const Text('Reset sample fences'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFenceRow(BuildContext context, GeofenceConfig config) {
    final live = liveStates[config.id];
    final liveLabel = live == null
        ? 'unknown'
        : live
            ? 'inside'
            : 'outside';
    final stored = persistedStates[config.id];
    final storedLabel = stored == null
        ? 'No events stored'
        : '${stored.state} (${stored.approved ? 'approved' : 'pending'})';
    final storedDate = stored?.eventDate.toLocal();
    return DraftModeUIRow(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  config.label,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ),
              if (onDeleteFence != null)
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () => onDeleteFence!(config.id),
                  child: const Text(
                    'Remove',
                    style: TextStyle(color: CupertinoColors.systemRed),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Lat ${config.lat.toStringAsFixed(4)}, Lng ${config.lng.toStringAsFixed(4)}',
            style: const TextStyle(fontSize: 14),
          ),
          Text(
            'Radius: ${config.radiusMeters.toStringAsFixed(0)} m',
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text('Live state: $liveLabel'),
          Text(
            'Persisted: $storedLabel${storedDate != null ? ' @ ${storedDate.toString()}' : ''}',
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text('No fences configured'),
          SizedBox(height: 4),
          Text('Use "Add geofence" to register your first region.'),
        ],
      );

  Future<void> _showAddFenceDialog(BuildContext context) async {
    if (onAddFence == null) return;
    final labelController = TextEditingController();
    final latController = TextEditingController();
    final lngController = TextEditingController();
    final radiusController = TextEditingController(text: '120');
    String? error;

    _FenceDraft? result;
    try {
      result = await showCupertinoDialog<_FenceDraft>(
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (context, setState) {
            return CupertinoAlertDialog(
              title: const Text('Add geofence'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 12),
                  CupertinoTextField(
                    controller: labelController,
                    placeholder: 'Label',
                    autofocus: true,
                  ),
                  const SizedBox(height: 8),
                  CupertinoTextField(
                    controller: latController,
                    placeholder: 'Latitude',
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                  ),
                  const SizedBox(height: 8),
                  CupertinoTextField(
                    controller: lngController,
                    placeholder: 'Longitude',
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                  ),
                  const SizedBox(height: 8),
                  CupertinoTextField(
                    controller: radiusController,
                    placeholder: 'Radius meters',
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                  ),
                  if (error != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      error!,
                      style: const TextStyle(
                        color: CupertinoColors.systemRed,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ],
              ),
              actions: [
                CupertinoDialogAction(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                CupertinoDialogAction(
                  isDefaultAction: true,
                  onPressed: () {
                    final label = labelController.text.trim();
                    final lat = double.tryParse(latController.text);
                    final lng = double.tryParse(lngController.text);
                    final radius = double.tryParse(radiusController.text);
                    if (label.isEmpty ||
                        lat == null ||
                        lng == null ||
                        radius == null) {
                      setState(() {
                        error = 'Enter label, latitude/longitude, and radius.';
                      });
                      return;
                    }
                    Navigator.of(context).pop(
                      _FenceDraft(
                        label: label,
                        latitude: lat,
                        longitude: lng,
                        radiusMeters: radius,
                      ),
                    );
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        ),
      );
    } finally {
      labelController.dispose();
      latController.dispose();
      lngController.dispose();
      radiusController.dispose();
    }

    if (result != null) {
      await onAddFence!(
        label: result.label,
        latitude: result.latitude,
        longitude: result.longitude,
        radiusMeters: result.radiusMeters,
      );
    }
  }
}

class _FenceDraft {
  const _FenceDraft({
    required this.label,
    required this.latitude,
    required this.longitude,
    required this.radiusMeters,
  });

  final String label;
  final double latitude;
  final double longitude;
  final double radiusMeters;
}
