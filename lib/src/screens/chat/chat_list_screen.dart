// lib/src/screens/chat/chat_list_screen.dart

import 'dart:convert';
import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../config/constants.dart';
import '../../services/constants.dart';
import '../../services/storage_service.dart';
import '../profile/profile_screen.dart';
import 'chat_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  List<Map<String, dynamic>> _chats = [];
  bool _loading = true;

  final DatabaseReference _db =
  FirebaseDatabase.instance.ref('chats');

  @override
  void initState() {
    super.initState();
    _loadChats();
  }

  // ───────────────── LOAD CHAT ROOMS ─────────────────

  Future<void> _loadChats() async {
    try {
      final token = await StorageService.getToken();
      if (token == null) return;

      final res = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/chat/my/'),
        headers: {'Authorization': 'Token $token'},
      );

      if (res.statusCode == 200) {
        final List list = List.from(
          res.body.isNotEmpty ? jsonDecode(res.body) : [],
        );

        setState(() {
          _chats = list.cast<Map<String, dynamic>>();
          _loading = false;
        });
      }
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  // ───────────────── PROFILE PREVIEW MODAL (BIG IMAGE) ─────────────────

  void _showProfilePreview(
      BuildContext context,
      Map<String, dynamic> profile,
      ) {
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(16),
          child: Stack(
            children: [
              BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                child: Container(color: Colors.black.withOpacity(0.5)),
              ),
              Center(
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.85,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFF00FF7F),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: CachedNetworkImage(
                          imageUrl: profile['profile_image'] ??
                              Constants.defaultProfilePath,
                          width: double.infinity,
                          height: 300, // 🔥 BIG IMAGE
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        profile['username'] ?? '',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      IconButton(
                        icon: const Icon(
                          Icons.person,
                          color: Color(0xFF00FF7F),
                          size: 32,
                        ),
                        onPressed: () {
                          final userId = profile['user_id'];
                          Navigator.pop(context);

                          if (userId != null) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    ProfileScreen(userId: userId),
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ───────────────── BUILD ─────────────────

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => true,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          title: const Text(
            'Chats',
            style: TextStyle(color: Colors.white),
          ),
        ),
        body: _loading
            ? const Center(
          child: CircularProgressIndicator(
            color: Color(0xFF00FF7F),
          ),
        )
            : _chats.isEmpty
            ? const Center(
          child: Text(
            'No chats yet',
            style: TextStyle(color: Colors.white54),
          ),
        )
            : ListView.builder(
          itemCount: _chats.length,
          itemBuilder: (context, index) {
            final chat = _chats[index];
            final chatId = chat['id'];
            final other = chat['other_user'];
            final otherUserId = other['id'];
            final username = other['username'];

            return FutureBuilder<Map<String, dynamic>>(
              future: _fetchUserProfile(otherUserId),
              builder: (context, profileSnap) {
                final profile = profileSnap.data;
                final profileImage =
                    profile?['profile_image'] ??
                        Constants.defaultProfilePath;

                return StreamBuilder(
                  stream: _db
                      .child(chatId)
                      .child('messages')
                      .limitToLast(1)
                      .onValue,
                  builder: (context, snap) {
                    String lastMessage = 'Say hi 👋';

                    if (snap.hasData &&
                        snap.data!.snapshot.value != null) {
                      final map = Map<String, dynamic>.from(
                        snap.data!.snapshot.value as Map,
                      );
                      final msg = map.values.first
                      as Map<dynamic, dynamic>;
                      lastMessage =
                          msg['text']?.toString() ?? '';
                    }

                    return ListTile(
                      leading: GestureDetector(
                        onTap: () {
                          if (profile != null) {
                            _showProfilePreview(
                                context, profile);
                          }
                        },
                        child: CircleAvatar(
                          radius: 24,
                          backgroundImage:
                          CachedNetworkImageProvider(
                              profileImage),
                        ),
                      ),
                      title: Text(
                        username,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        lastMessage,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: Colors.white54),
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatScreen(
                              chatRoomId: chatId,
                              otherUsername: username,
                              otherUserId: otherUserId,
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }

  // ───────────────── FETCH PROFILE ─────────────────

  Future<Map<String, dynamic>> _fetchUserProfile(int userId) async {
    final token = await StorageService.getToken();
    final res = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/profiles/$userId/'),
      headers: {'Authorization': 'Token $token'},
    );

    if (res.statusCode == 200) {
      return Map<String, dynamic>.from(jsonDecode(res.body));
    }

    return {};
  }
}
