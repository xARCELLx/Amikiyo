import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

class NotificationService {
  static final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  // 🔥 Used for navigation from push
  static final GlobalKey<NavigatorState> navigatorKey =
  GlobalKey<NavigatorState>();

  // ───────────────── INIT ─────────────────

  static Future<void> initialize() async {
    // 🔥 Request permission
    await _fcm.requestPermission();

    // 🔥 Get token (already using)
    final token = await _fcm.getToken();
    print("🔥 FCM TOKEN: $token");

    // 🔥 Foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print("📩 Foreground Notification: ${message.notification?.title}");
    });

    // 🔥 When app opened via notification
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleNavigation(message);
    });

    // 🔥 When app is terminated and opened via notification
    final initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      _handleNavigation(initialMessage);
    }
  }

  // ───────────────── NAVIGATION ─────────────────

  static void _handleNavigation(RemoteMessage message) {
    final data = message.data;

    final type = data['type'];
    final postId = data['post_id'];
    final chatRoomId = data['chat_room_id'];

    print("🚀 Navigation Triggered: $data");

    if (type == 'like' || type == 'comment' || type == 'thought') {
      navigatorKey.currentState?.pushNamed('/home');
    } else if (type == 'follow') {
      navigatorKey.currentState?.pushNamed('/notifications');
    } else if (type == 'dm') {
      navigatorKey.currentState?.pushNamed('/home');
    }
  }
}