import 'package:flutter/widgets.dart';

class DraftModeLogger {
  final bool _active;
  DraftModeLogger(
    bool? active
  ) :
    _active = active ?? false
  ;

  void notice(String message) {
    if (_active) debugPrint(message);
  }
}
