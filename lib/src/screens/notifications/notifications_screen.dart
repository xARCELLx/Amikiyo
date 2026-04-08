import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';

import '../../services/constants.dart';
import '../../services/storage_service.dart';

import '../profile/profile_screen.dart';
import '../profile/post_detail_modal.dart';
import '../chat/chat_screen.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  List<dynamic> _notifications = [];

  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  // ───────────────── FETCH ─────────────────

  Future<void> _fetchNotifications() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final token = await StorageService.getToken();

      final res = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/notifications/'),
        headers: {'Authorization': 'Token $token'},
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);

        if (!mounted) return;

        setState(() {
          _notifications = data;
          _isLoading = false;
        });
      } else {
        throw Exception();
      }
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _hasError = true;
        _isLoading = false;
      });
    }
  }

  // ───────────────── MARK READ ─────────────────

  Future<void> _markAsRead(int id) async {
    try {
      final token = await StorageService.getToken();

      await http.post(
        Uri.parse('${ApiConstants.baseUrl}/notifications/$id/read/'),
        headers: {'Authorization': 'Token $token'},
      );
    } catch (_) {}
  }

  // ───────────────── FETCH POST ─────────────────

  Future<Map<String, dynamic>?> _fetchPost(int postId) async {
    try {
      final token = await StorageService.getToken();

      final res = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/posts/$postId/detail/'),
        headers: {'Authorization': 'Token $token'},
      );

      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
    } catch (_) {}

    return null;
  }

  // ───────────────── TIME ─────────────────

  String _formatTime(String time) {
    try {
      final date = DateTime.parse(time).toLocal();
      final diff = DateTime.now().difference(date);

      if (diff.inSeconds < 60) return "now";
      if (diff.inMinutes < 60) return "${diff.inMinutes}m";
      if (diff.inHours < 24) return "${diff.inHours}h";
      if (diff.inDays < 7) return "${diff.inDays}d";

      return "${date.day}/${date.month}";
    } catch (_) {
      return "";
    }
  }

  // ───────────────── ITEM (MODERN TILE) ─────────────────

  Widget _buildItem(Map<String, dynamic> notif) {
    final username = notif['sender_username'] ?? '';
    final text = notif['text'] ?? '';
    final pfp = notif['sender_pfp'];
    final isRead = notif['is_read'] ?? false;
    final time = _formatTime(notif['created_at']);

    final senderId = notif['sender_id'];
    final postId = notif['post'];
    final chatRoomId = notif['chat_room_id'];
    final type = notif['notification_type'];

    return GestureDetector(
      onTap: () async {
        final id = notif['id'];

        await _markAsRead(id);
        setState(() => notif['is_read'] = true);

        if (type == 'like' || type == 'comment' || type == 'thought') {
          if (postId != null) {
            final fullPost = await _fetchPost(postId);

            if (fullPost != null && context.mounted) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PostDetailModal(
                    post: fullPost,
                    heroTag: 'notif_post_$postId',
                  ),
                ),
              );
            }
          }
        } else if (type == 'follow') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProfileScreen(userId: senderId),
            ),
          );
        } else if (type == 'dm') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChatScreen(
                chatRoomId: chatRoomId,
                chatType: ChatType.private,
                otherUserId: senderId,
                title: username,
              ),
            ),
          );
        }
      },

      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          children: [
            // PROFILE
            CircleAvatar(
              radius: 22,
              backgroundImage:
              (pfp != null && pfp.toString().isNotEmpty)
                  ? CachedNetworkImageProvider(pfp)
                  : const AssetImage(
                  'assets/images/default_profile.png')
              as ImageProvider,
            ),

            const SizedBox(width: 12),

            // TEXT
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    username,
                    style: const TextStyle(
                      fontFamily: 'AnimeAce',
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    text.replaceFirst("$username ", ""),
                    style: const TextStyle(
                      fontFamily: 'AnimeAce',
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),

            // RIGHT SIDE
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  time,
                  style: const TextStyle(
                    fontFamily: 'AnimeAce',
                    color: Colors.white38,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 6),
                if (!isRead)
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFF00FF7F),
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ───────────────── STATES ─────────────────

  Widget _buildLoading() {
    return const Center(
      child: CircularProgressIndicator(color: Color(0xFF00FF7F)),
    );
  }

  Widget _buildError() {
    return Center(
      child: TextButton(
        onPressed: _fetchNotifications,
        child: const Text(
          "Retry",
          style: TextStyle(
            fontFamily: 'AnimeAce',
            color: Color(0xFF00FF7F),
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return const Center(
      child: Text(
        "No notifications yet",
        style: TextStyle(
          fontFamily: 'AnimeAce',
          color: Colors.white54,
        ),
      ),
    );
  }

  // ───────────────── MAIN ─────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,

      appBar: AppBar(
        title: const Text(
          "Notifications",
          style: TextStyle(fontFamily: 'AnimeAce'),
        ),
        backgroundColor: Colors.black,
        elevation: 0,
      ),

      body: RefreshIndicator(
        color: const Color(0xFF00FF7F),
        onRefresh: _fetchNotifications,
        child: _isLoading
            ? _buildLoading()
            : _hasError
            ? _buildError()
            : _notifications.isEmpty
            ? _buildEmpty()
            : ListView.builder(
          padding: const EdgeInsets.only(top: 8),
          itemCount: _notifications.length,
          itemBuilder: (_, i) =>
              _buildItem(_notifications[i]),
        ),
      ),
    );
  }
}