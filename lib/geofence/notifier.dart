import 'package:flutter/widgets.dart';
import 'confirm.dart';

/// Handles UI prompts for exit confirmation and exposes expiry metadata.
class DraftModeGeofenceNotifier {
  final GlobalKey<NavigatorState> _navigatorKey;
  final bool Function() _isAppInForeground;
  final bool Function() _isMounted;
  final DraftModeGeofenceConfirm _confirmDialog;
  final int expireStateMinutes;
  DraftModeGeofenceNotifier({
    required GlobalKey<NavigatorState> navigatorKey,
    required bool Function() isAppInForeground,
    required bool Function() isMounted,
    required DraftModeGeofenceConfirm confirmDialog,
    int? expireStateMinutes
  }) :
    _navigatorKey = navigatorKey,
    _isAppInForeground = isAppInForeground,
    _isMounted = isMounted,
    _confirmDialog = confirmDialog,
    expireStateMinutes = expireStateMinutes ?? 2
  ;
}
