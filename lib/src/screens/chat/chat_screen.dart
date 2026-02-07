// lib/src/screens/chat/chat_screen.dart

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../../services/constants.dart';
import '../../services/storage_service.dart';
import '../profile/post_detail_modal.dart';
import 'widgets/chat_post_bubble.dart';

class ChatScreen extends StatefulWidget {
  final String chatRoomId; // UUID from Django
  final int otherUserId;
  final String otherUsername;

  const ChatScreen({
    super.key,
    required this.chatRoomId,
    required this.otherUserId,
    required this.otherUsername,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  late DatabaseReference _messagesRef;

  /// Firebase UID → int mapping (your existing logic)
  final int myUserId = FirebaseAuth.instance.currentUser!.uid.hashCode;

  @override
  void initState() {
    super.initState();
    _messagesRef = FirebaseDatabase.instance
        .ref('chats/${widget.chatRoomId}/messages');
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ───────────────── SEND TEXT MESSAGE ─────────────────

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    _messagesRef.push().set({
      'type': 'text',
      'sender_id': myUserId,
      'text': text,
      'timestamp': ServerValue.timestamp,
    });

    _controller.clear();
    _scrollToBottom();
  }

  // ───────────────── SCROLL ─────────────────

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 150), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ───────────────── OPEN POST FROM CHAT ─────────────────
  // 🔥 THIS IS THE CRITICAL FIX

  Future<void> _openPostFromChat({
    required int postId,
    required int authorUserId,
  }) async {
    final token = await StorageService.getToken();
    if (token == null || !mounted) return;

    try {
      final res = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/posts/user/$authorUserId/'),
        headers: {'Authorization': 'Token $token'},
      );

      if (res.statusCode != 200) return;

      final List posts = jsonDecode(res.body);

      final fullPost = posts.firstWhere(
            (p) => p['id'] == postId,
        orElse: () => null,
      );

      if (fullPost == null || !mounted) return;

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => PostDetailModal(
          post: Map<String, dynamic>.from(fullPost),
          heroTag: 'chat_post_$postId',
        ),
      );
    } catch (e) {
      debugPrint('OPEN CHAT POST ERROR: $e');
    }
  }

  // ───────────────── TEXT MESSAGE BUBBLE ─────────────────

  Widget _textBubble(String text, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isMe ? const Color(0xFF00FF7F) : Colors.grey[800],
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isMe ? Colors.black : Colors.white,
          ),
        ),
      ),
    );
  }

  // ───────────────── UI ─────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          widget.otherUsername,
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: Column(
        children: [
          /// ── MESSAGES ─────────────────
          Expanded(
            child: StreamBuilder<DatabaseEvent>(
              stream: _messagesRef.onValue,
              builder: (context, snapshot) {
                if (!snapshot.hasData ||
                    snapshot.data!.snapshot.value == null) {
                  return const Center(
                    child: Text(
                      'No messages yet',
                      style: TextStyle(color: Colors.white54),
                    ),
                  );
                }

                final raw =
                snapshot.data!.snapshot.value as Map<dynamic, dynamic>;

                final messages = raw.entries
                    .map<Map<String, dynamic>>(
                      (e) => Map<String, dynamic>.from(e.value),
                )
                    .toList()
                  ..sort((a, b) {
                    final ta = a['timestamp'] ?? 0;
                    final tb = b['timestamp'] ?? 0;
                    return ta.compareTo(tb);
                  });

                _scrollToBottom();

                return ListView.builder(
                  controller: _scrollController,
                  itemCount: messages.length,
                  itemBuilder: (_, i) {
                    final msg = messages[i];
                    final bool isMe = msg['sender_id'] == myUserId;

                    // ── POST MESSAGE ──
                    if (msg['type'] == 'post' && msg['post'] != null) {
                      final preview =
                      Map<String, dynamic>.from(msg['post']);

                      return ChatPostBubble(
                        postPreview: preview,
                        isMe: isMe,
                        onTap: () => _openPostFromChat(
                          postId: msg['post_id'],
                          authorUserId:
                          msg['post']['author_user_id'] ??
                              widget.otherUserId,
                        ),
                      );
                    }

                    // ── TEXT MESSAGE ──
                    return _textBubble(msg['text'] ?? '', isMe);
                  },
                );
              },
            ),
          ),

          /// ── INPUT ─────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            color: Colors.black,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      hintStyle:
                      const TextStyle(color: Colors.white54),
                      filled: true,
                      fillColor: Colors.grey[900],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.send,
                    color: Color(0xFF00FF7F),
                  ),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
