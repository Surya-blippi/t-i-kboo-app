import 'package:flutter/services.dart';

/// Bridges iOS "open file in tikboo" (share sheet / document open) to Flutter.
/// Android uses receive_sharing_intent instead — this is iOS-only.
class IosShareChannel {
  static const _channel = MethodChannel('tikboo/shared');

  /// Set [onFile] to be called whenever a chat file is shared while running,
  /// and immediately checks for a file that launched the app cold.
  static void init(void Function(String path) onFile) {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onSharedFile' && call.arguments is String) {
        onFile(call.arguments as String);
      }
    });
    _channel
        .invokeMethod<String>('getInitialSharedFile')
        .then((path) {
      if (path != null && path.isNotEmpty) onFile(path);
    }).catchError((_) {});
  }
}
