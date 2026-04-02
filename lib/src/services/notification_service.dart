import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:dio/dio.dart';

import '../services/constants.dart';
import '../services/storage_service.dart';

class NotificationService {
  static final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  static Future<void> init() async {
    // 1. Ask permission
    await _fcm.requestPermission();

    // 2. Get token
    final token = await _fcm.getToken();

    print("🔥 DEVICE TOKEN: $token");

    if (token != null) {
      await _sendTokenToBackend(token);
    }

    // 3. Handle token refresh
    _fcm.onTokenRefresh.listen((newToken) async {
      print("♻️ NEW TOKEN: $newToken");
      await _sendTokenToBackend(newToken);
    });
  }

  static Future<void> _sendTokenToBackend(String token) async {
    try {
      final authToken = await StorageService.getToken();

      await Dio().post(
        '${ApiConstants.baseUrl}/notifications/save-token/',
        data: {"token": token},
        options: Options(
          headers: {
            "Authorization": "Token $authToken",
          },
        ),
      );

      print("✅ Token saved to backend");
    } catch (e) {
      print("❌ Error sending token: $e");
    }
  }
}