import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_database/firebase_database.dart';

import '../../services/constants.dart';
import '../../services/storage_service.dart';

class SharePostBottomSheet extends StatefulWidget {
  final Map<String, dynamic> post;

  const SharePostBottomSheet({
    super.key,
    required this.post,
  });

  @override
  State<SharePostBottomSheet> createState() => _SharePostBottomSheetState();
}

class _SharePostBottomSheetState extends State<SharePostBottomSheet> {
  // ───────────────── CORE STATE ─────────────────

  final List<Map<String, dynamic>> _users = [];
  bool _loading = true;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  // ───────────────── FETCH FOLLOWING + CHAT USERS ─────────────────

  Future<void> _fetchUsers() async {
    try {
      final token = await StorageService.getToken();
      final myId = await StorageService.getUserId();

      if (token == null || myId == null) {
        setState(() => _loading = false);
        return;
      }

      final followingRes = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/profiles/$myId/following/'),
        headers: {'Authorization': 'Token $token'},
      );

      final chatRes = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/chat/my/'),
        headers: {'Authorization': 'Token $token'},
      );

      final List following =
      followingRes.statusCode == 200 ? jsonDecode(followingRes.body) : [];

      final List chats =
      chatRes.statusCode == 200 ? jsonDecode(chatRes.body) : [];

      final Map<int, Map<String, dynamic>> uniqueUsers = {};

      // FOLLOWING USERS
      for (final u in following) {
        final int? uid = u['user_id'];
        if (uid != null) {
          uniqueUsers[uid] = Map<String, dynamic>.from(u);
        }
      }

      // CHAT USERS
      for (final c in chats) {
        if (c['other_user'] != null) {
          final u = c['other_user'];
          final int? uid = u['id'];
          if (uid != null) {
            uniqueUsers[uid] = Map<String, dynamic>.from(u);
          }
        }
      }

      setState(() {
        _users
          ..clear()
          ..addAll(uniqueUsers.values);
        _loading = false;
      });
    } catch (e) {
      debugPrint('SHARE USERS ERROR: $e');
      setState(() => _loading = false);
    }
  }

  // ───────────────── SEND POST (FIREBASE ONLY) ─────────────────

  Future<void> _sendPost(Map<String, dynamic> user) async {
    if (_sending) return;

    setState(() => _sending = true);

    try {
      final token = await StorageService.getToken();
      final myId = await StorageService.getUserId();
      final myUsername = await StorageService.getUsername();

      if (token == null || myId == null) return;

      // 1️⃣ Get or create private chat room
      final res = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/chat/get-or-create/'),
        headers: {
          'Authorization': 'Token $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'user_id': user['user_id'] ?? user['id'],
        }),
      );

      if (res.statusCode != 200) {
        debugPrint("Chat creation failed");
        return;
      }

      final data = jsonDecode(res.body);
      final String chatRoomId = data['id'];

      // 2️⃣ Push NEW ARCHITECTURE message to Firebase
      final messageRef = FirebaseDatabase.instance
          .ref('chats/$chatRoomId/messages')
          .push();

      await messageRef.set({
        "type": "post",
        "senderId": myId,
        "senderUsername": myUsername ?? "",   // 🔥 NEW
        "postId": widget.post['id'],          // 🔥 ONLY ID
        "timestamp": ServerValue.timestamp,
        "replyTo": null,
        "deletedForEveryone": false,
      });

      if (mounted) Navigator.pop(context);
    } catch (e) {
      debugPrint('SEND POST ERROR: $e');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  // ───────────────── UI ─────────────────

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),

          const Text(
            'Share post',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          const Divider(color: Colors.white12),

          Expanded(
            child: _loading
                ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF00FF7F),
              ),
            )
                : _users.isEmpty
                ? const Center(
              child: Text(
                'No users available',
                style: TextStyle(color: Colors.white54),
              ),
            )
                : ListView.builder(
              itemCount: _users.length,
              itemBuilder: (_, i) {
                final u = _users[i];
                final String username =
                    u['username'] ?? 'User';
                final String? image =
                u['profile_image'];

                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.grey[800],
                    backgroundImage: image != null &&
                        image.startsWith('http')
                        ? NetworkImage(image)
                        : null,
                    child: image == null
                        ? const Icon(
                      Icons.person,
                      color: Colors.white54,
                    )
                        : null,
                  ),
                  title: Text(
                    username,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  trailing: IconButton(
                    icon: const Icon(
                      Icons.send,
                      color: Color(0xFF00FF7F),
                    ),
                    onPressed: () => _sendPost(u),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
