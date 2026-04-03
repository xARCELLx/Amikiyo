import 'dart:convert';
import 'package:amikiyo/src/services/constants.dart';
import 'package:amikiyo/src/services/storage_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import '../screens/profile/profile_screen.dart';
import '../screens/profile/post_detail_modal.dart';
import '../screens/chat/chat_screen.dart';
import 'package:http/http.dart' as http;

class NotificationService {
  static final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  // 🔥 GLOBAL NAV KEY (VERY IMPORTANT)
  static final GlobalKey<NavigatorState> navigatorKey =
  GlobalKey<NavigatorState>();

  // ───────────────── INIT ─────────────────

  static Future<void> initialize() async {
    await _requestPermission();
    await _setupToken();
    _setupListeners();
  }

  // ───────────────── PERMISSION ─────────────────

  static Future<void> _requestPermission() async {
    await _fcm.requestPermission();
  }

  // ───────────────── TOKEN ─────────────────

  static Future<void> _setupToken() async {
    final token = await _fcm.getToken();

    if (token != null) {
      print("🔥 FCM TOKEN: $token");

      // TODO: send this token to backend
      // You already did this → GOOD
    }
  }

  // ───────────────── LISTENERS ─────────────────

  static void _setupListeners() {
    // 🔥 APP OPEN FROM TERMINATED STATE
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) {
        _handleNotificationTap(message.data);
      }
    });

    // 🔥 APP IN BACKGROUND → USER TAP
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      _handleNotificationTap(message.data);
    });

    // 🔥 FOREGROUND (optional UI later)
    FirebaseMessaging.onMessage.listen((message) {
      print("📩 Foreground notification: ${message.notification?.title}");
    });
  }

  // ───────────────── NAVIGATION LOGIC ─────────────────

  static void _handleNotificationTap(Map<String, dynamic> data) {
    final type = data['type'];

    final navigator = navigatorKey.currentState;
    if (navigator == null) return;

    print("🔥 Notification Clicked: $data");

    switch (type) {
      case "like":
      case "comment":
      case "post":
      case "thought":
        final postId = int.tryParse(data['post_id'] ?? '');
        if (postId != null) {
          _openPost(postId);
        }
        break;

      case "follow":
        final userId = int.tryParse(data['user_id'] ?? '');
        if (userId != null) {
          navigator.push(
            MaterialPageRoute(
              builder: (_) => ProfileScreen(userId: userId),
            ),
          );
        }
        break;

      case "dm":
        final chatRoomId = data['chat_room_id'];
        if (chatRoomId != null) {
          navigator.push(
            MaterialPageRoute(
              builder: (_) => ChatScreen(
                chatRoomId: chatRoomId,
                chatType: ChatType.private,
                title: "Chat",
              ),
            ),
          );
        }
        break;

      default:
        print("Unknown notification type");
    }
  }

  // ───────────────── OPEN POST ─────────────────

  static Future<void> _openPost(int postId) async {
    final navigator = navigatorKey.currentState;
    if (navigator == null) return;

    try {
      // 🔥 FETCH POST FROM API
      final token = await StorageService.getToken();

      final res = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/posts/$postId/detail/'),
        headers: {
          'Authorization': 'Token $token',
        },
      );

      if (res.statusCode != 200) {
        print("❌ Failed to fetch post");
        return;
      }

      final post = jsonDecode(res.body);

      // 🔥 OPEN MODAL WITH FULL DATA
      showModalBottomSheet(
        context: navigator.context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => PostDetailModal(
          post: post,
          heroTag: 'notif_post_$postId',
        ),
      );
    } catch (e) {
      print("🚨 Error opening post: $e");
    }
  }
}