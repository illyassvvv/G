import 'package:flutter/services.dart';

class ExternalPlayerService {
  static const _channel = MethodChannel('com.vargastv/external_player');

  /// Check if MX Player (free or pro) is installed on the device
  static Future<bool> isMxPlayerInstalled() async {
    try {
      final result = await _channel.invokeMethod<bool>('isMxPlayerInstalled');
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  /// Launch MX Player with the given stream URL and title
  static Future<bool> launchMxPlayer({
    required String url,
    required String title,
  }) async {
    try {
      final result = await _channel.invokeMethod<bool>('launchMxPlayer', {
        'url': url,
        'title': title,
      });
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  /// Open Play Store / app store to download MX Player
  static Future<void> openMxPlayerStore() async {
    try {
      await _channel.invokeMethod('openMxPlayerStore');
    } on PlatformException {
      // Silently fail - store might not be available
    }
  }
}
