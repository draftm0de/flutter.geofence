import 'package:draftmode_geofence/geofence/notifier/background.dart';
import 'package:draftmode_ui/confirm.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform;
import 'listener.dart';

/// Handles UI prompts for exit confirmation and exposes expiry metadata.
typedef _ShowActionNotification =
    Future<void> Function({
      required int id,
      required String title,
      required String body,
    });

class DraftModeGeofenceNotifier {
  final GlobalKey<NavigatorState> _navigatorKey;
  final bool Function() _isAppInForeground;
  final bool Function() _isMounted;
  final _ShowActionNotification _showActionNotification;
  final int expireStateMinutes;
  DraftModeGeofenceNotifier({
    required GlobalKey<NavigatorState> navigatorKey,
    required bool Function() isAppInForeground,
    required bool Function() isMounted,
    _ShowActionNotification? showActionNotification,
    int? expireStateMinutes,
  }) : _navigatorKey = navigatorKey,
       _isAppInForeground = isAppInForeground,
       _isMounted = isMounted,
       _showActionNotification =
           showActionNotification ??
           DraftModeGeofenceBackgroundNotifier.instance.showActionNotification,
       expireStateMinutes = expireStateMinutes ?? 2;

  static bool get isIOS => defaultTargetPlatform == TargetPlatform.iOS;

  /// Requests user confirmation for the given [event]. When the app cannot
  /// surface a dialog (for example because it is backgrounded) we post a local
  /// notification so the user can respond later. When a dialog is shown we
  /// delegate to `DraftModeUIConfirm` from the shared `draftmode_ui` package to
  /// ensure consistent styling and optional auto-confirm countdowns. Custom
  /// button labels can be provided so host applications can localize the action
  /// text. Supply [onConfirm] to run work (for example persisting geofence
  /// state) whenever the affirmative action is taken, even when it originates
  /// from a background notification.
  Future<void> confirmMovement(
    DraftModeGeofenceEvent event, {
    required String title,
    required String message,
    required Future<void> Function() onConfirm,
    Duration? autoConfirmAfter,
    String? confirmLabel,
    String? cancelLabel,
  }) async {
    final BuildContext? context = await getBuildContext();
    if (!_canShowForegroundDialog(context)) {
      final id = DateTime.now().millisecondsSinceEpoch;
      await _showActionNotification(id: id, title: title, body: message);

      return;
    }

    final bool? result = await DraftModeUIConfirm.show(
      context: context!,
      title: title,
      message: message,
      autoConfirm: autoConfirmAfter,
      confirmLabel: confirmLabel,
      cancelLabel: cancelLabel,
      barrierDismissible: !isIOS,
      mode: DraftModeUIConfirmStyle.confirm,
    );
    if (result == true) {
      await onConfirm();
    }
  }

  Future<BuildContext?> getBuildContext() async {
    final navigatorState = _navigatorKey.currentState;
    if (navigatorState == null) return null;

    final BuildContext buildContext =
        navigatorState.overlay?.context ?? navigatorState.context;

    return buildContext;
  }

  bool _canShowForegroundDialog(BuildContext? context) {
    if (!_isMounted()) return false;
    if (!_isAppInForeground()) return false;
    return context != null;
  }
}
