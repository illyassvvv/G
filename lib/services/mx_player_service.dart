import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

class MxPlayerService {
  // MX Player package names
  static const String _mxFree = 'com.mxtech.videoplayer.ad';
  static const String _mxPro = 'com.mxtech.videoplayer.pro';

  /// Try to launch the stream directly in MX Player.
  /// Returns true if launched successfully, false if MX Player is not installed.
  static Future<bool> launchInMxPlayer({
    required String streamUrl,
    required String title,
  }) async {
    // Try MX Player Pro first, then free version
    for (final package in [_mxPro, _mxFree]) {
      try {
        final intent = AndroidIntent(
          action: 'action_view',
          data: streamUrl,
          type: 'video/*',
          package: package,
          flags: <int>[Flag.FLAG_ACTIVITY_NEW_TASK],
          arguments: <String, dynamic>{
            'title': title,
            'decode_mode': 1, // HW+ decoder for best performance
          },
        );
        await intent.launch();
        return true;
      } catch (e) {
        debugPrint('MxPlayerService: Failed to launch $package: $e');
        continue;
      }
    }
    return false;
  }

  /// Open MX Player page on Play Store
  static Future<void> openPlayStore() async {
    const playStoreUrl =
        'market://details?id=com.mxtech.videoplayer.ad';
    final uri = Uri.parse(playStoreUrl);
    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        // Fallback to web URL if market:// doesn't work
        await launchUrl(
          Uri.parse(
            'https://play.google.com/store/apps/details?id=com.mxtech.videoplayer.ad',
          ),
          mode: LaunchMode.externalApplication,
        );
      }
    } catch (e) {
      debugPrint('MxPlayerService: Failed to open Play Store: $e');
      // Try web fallback
      await launchUrl(
        Uri.parse(
          'https://play.google.com/store/apps/details?id=com.mxtech.videoplayer.ad',
        ),
        mode: LaunchMode.externalApplication,
      );
    }
  }
}
