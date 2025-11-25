import 'package:draftmode_geofence/geofence.dart';
import 'package:draftmode_notifier_example/entity/config.dart';
import 'package:draftmode_ui/buttons.dart';
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
    this.onFenceTap,
    super.key,
  });

  final List<GeofenceConfig> configs;
  final Map<String, bool> liveStates;
  final Map<String, DraftModeGeofenceStateEntity?> persistedStates;
  final bool isLoading;
  final Future<void> Function()? onRefreshStates;
  final Future<void> Function()? onResetGeofences;
  final Future<void> Function()? onAddFence;
  final ValueChanged<GeofenceConfig>? onFenceTap;

  @override
  Widget build(BuildContext context) {
    return DraftModeUIPageExample(
      title: 'Geofence Demo',
      bottomTrailing: (onAddFence == null)
          ? null
          : [
              DraftModePageNavigationBottomItem(
                icon: DraftModeUIButtons.plus,
                onTap: onAddFence,
              ),
            ],
      children: [
        DraftModeUISection(
          header: 'Active geofences',
          children: [
            if (isLoading)
              const DraftModeUIRow(
                Center(child: CupertinoActivityIndicator()),
              )
            else
              DraftModeUIList<GeofenceConfig>(
                isPending: configs.isEmpty,
                items: configs,
                itemBuilder: (GeofenceConfig item, bool selected) =>
                    _buildFenceRow(context, item),
                emptyPlaceholder: _buildEmptyState(context),
                onTap: onFenceTap == null
                    ? null
                    : (item) => onFenceTap?.call(item),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          config.label,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
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
}
