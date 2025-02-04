 import 'package:flutter/foundation.dart';

class LoggerConfig {
  static void init() {
    if (kDebugMode) {
      // Override Flutter's error logger
      FlutterError.onError = (FlutterErrorDetails details) {
        if (!details.toString().contains('ViewRootImpl') && 
            !details.toString().contains('MotionEvent') &&
            !details.toString().contains('dispatchPointerEvent')) {
          FlutterError.presentError(details);
        }
      };

      // Override print
      debugPrint = (String? message, {int? wrapWidth}) {
        if (message != null && 
            !message.contains('ViewRootImpl') && 
            !message.contains('MotionEvent') &&
            !message.contains('dispatchPointerEvent') &&
            !message.contains('D/') &&
            !message.contains('processMotionEvent')) {
          debugPrintSynchronously(message, wrapWidth: wrapWidth);
        }
      };
    }
  }
}
