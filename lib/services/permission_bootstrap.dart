import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PermissionBootstrap {
  static const String _prefsKey = 'permissions_requested_v1';

  static Future<void> requestInitialPermissions() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_prefsKey) == true) return;

    if (kIsWeb) {
      await prefs.setBool(_prefsKey, true);
      return;
    }

    final platform = defaultTargetPlatform;
    if (platform != TargetPlatform.android && platform != TargetPlatform.iOS) {
      await prefs.setBool(_prefsKey, true);
      return;
    }

    try {
      await [
        Permission.camera,
        Permission.notification,
      ].request();
    } finally {
      await prefs.setBool(_prefsKey, true);
    }
  }
}
