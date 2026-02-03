import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

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
    _fetchShareableUsers();
  }

  // ───────────────── FETCH USERS (FOLLOWING + CHATS) ─────────────────

  Future<void> _fetchShareableUsers() async {
    try {
      final token = await StorageService.getToken();
      final myId = await StorageService.getUserId();

      if (token == null || myId == null) {
        setState(() => _loading = false);
        return;
      }

      // ── FETCH FOLLOWING USERS ──
      final followingRes = await http.get(
        Uri.parse(
            '${ApiConstants.baseUrl}/profiles/$myId/following/'),
        headers: {'Authorization': 'Token $token'},
      );

      final List following = followingRes.statusCode == 200
          ? jsonDecode(followingRes.body)
          : [];

      // ── FETCH CHAT USERS ──
      final chatRes = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/chat/my/'),
        headers: {'Authorization': 'Token $token'},
      );

      final List chats = chatRes.statusCode == 200
          ? jsonDecode(chatRes.body)
          : [];

      // ── EXTRACT OTHER USERS FROM CHATS ──
      final List<Map<String, dynamic>> chatUsers = chats
          .where((c) => c['other_user'] != null)
          .map<Map<String, dynamic>>(
              (c) => Map<String, dynamic>.from(c['other_user']))
          .toList();

      // ── MERGE & REMOVE DUPLICATES ──
      final Map<int, Map<String, dynamic>> uniqueUsers = {};

      for (final u in [...following, ...chatUsers]) {
        final int? uid = u['user_id'] ?? u['id'];
        if (uid != null) {
          uniqueUsers[uid] = Map<String, dynamic>.from(u);
        }
      }

      setState(() {
        _users.clear();
        _users.addAll(uniqueUsers.values);
        _loading = false;
      });
    } catch (e) {
      debugPrint('SHARE POST ERROR: $e');
      setState(() => _loading = false);
    }
  }

  // ───────────────── SEND POST (FIREBASE HOOK) ─────────────────

  Future<void> _sendPostToUser(Map<String, dynamic> user) async {
    if (_sending) return;

    setState(() => _sending = true);

    try {
      /*
        🔥 THIS IS WHERE YOU SEND TO FIREBASE 🔥

        Example payload you should send:
        {
          type: "post",
          post_id: widget.post['id'],
          image: widget.post['image'],
          caption: widget.post['caption'],
          sender_id: myId,
          receiver_id: user['user_id']
        }
      */

      Navigator.pop(context);
    } catch (_) {
      setState(() => _sending = false);
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

          // ── HEADER ─────────────────
          const Text(
            'Share post',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          const Divider(color: Colors.white12),

          // ── USER LIST ─────────────────
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
              itemBuilder: (_, index) {
                final user = _users[index];
                final String username =
                    user['username'] ?? '';
                final String? image =
                user['profile_image'];

                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.grey[800],
                    backgroundImage: image != null &&
                        image.startsWith('http')
                        ? NetworkImage(image)
                        : null,
                    child: image == null
                        ? const Icon(Icons.person,
                        color: Colors.white54)
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
                    onPressed: () =>
                        _sendPostToUser(user),
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
