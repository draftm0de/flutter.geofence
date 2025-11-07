import 'package:draftmode_ui/confirm.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform;
import 'listener.dart';

/// Handles UI prompts for exit confirmation and exposes expiry metadata.
class DraftModeGeofenceNotifier {
  final GlobalKey<NavigatorState> _navigatorKey;
  final bool Function() _isAppInForeground;
  final bool Function() _isMounted;
  final int expireStateMinutes;
  DraftModeGeofenceNotifier({
    required GlobalKey<NavigatorState> navigatorKey,
    required bool Function() isAppInForeground,
    required bool Function() isMounted,
    int? expireStateMinutes,
  }) :
    _navigatorKey = navigatorKey,
    _isAppInForeground = isAppInForeground,
    _isMounted = isMounted,
    expireStateMinutes = expireStateMinutes ?? 2
  ;

  static bool get isIOS => defaultTargetPlatform == TargetPlatform.iOS;

  /// Requests user confirmation for the given [event]. When the app cannot
  /// surface a dialog (for example because it is backgrounded) the method
  /// returns `true` so callers can auto-approve the movement. When a dialog is
  /// shown we delegate to `DraftModeUIConfirm` from the shared `draftmode_ui`
  /// package to ensure consistent styling and optional auto-confirm countdowns.
  /// Custom button labels can be provided so host applications can localize the
  /// action text.
  Future<bool> confirmMovement(
      DraftModeGeofenceEvent event, {
        required String title,
        required String message,
        Duration? autoConfirmAfter,
        String? confirmLabel,
        String? cancelLabel,
      }) async {
    final BuildContext? context = await getBuildContext();
    if (!_canShowForegroundDialog(context)) {
      final movement = event.entering ? 'enter' : 'exit';
      debugPrint(
        'confirmMovement:$movement auto-approved (foreground context unavailable)',
      );
      return true;
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

    return result ?? false;
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
