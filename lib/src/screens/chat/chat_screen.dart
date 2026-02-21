// lib/src/screens/chat/chat_screen.dart

import 'dart:convert';
import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../../config/constants.dart';
import '../../services/constants.dart';
import '../../services/storage_service.dart';
import '../profile/profile_screen.dart';
import '../profile/post_detail_modal.dart';
import 'widgets/chat_post_bubble.dart';

enum ChatType { private, group }

class ChatScreen extends StatefulWidget {
  final String chatRoomId;
  final int? otherUserId;
  final String? otherUsername;

  final ChatType chatType;
  final String? title;

  const ChatScreen({
    Key? key,
    required this.chatRoomId,
    this.otherUserId,
    this.otherUsername,
    this.chatType = ChatType.private,
    this.title,
  }) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  late final DatabaseReference _messagesRef;

  Map<String, dynamic>? _profileData;

  final int myUserId =
      FirebaseAuth.instance.currentUser!.uid.hashCode;

  @override
  void initState() {
    super.initState();
    _messagesRef = _buildRef();
    _loadHeaderData();
  }

  DatabaseReference _buildRef() {
    if (widget.chatType == ChatType.private) {
      return FirebaseDatabase.instance
          .ref('chats/${widget.chatRoomId}/messages');
    } else {
      return FirebaseDatabase.instance
          .ref('group_chats/${widget.chatRoomId}/messages');
    }
  }

  Future<void> _loadHeaderData() async {
    try {
      final token = await StorageService.getToken();
      if (token == null) return;

      if (widget.chatType == ChatType.private &&
          widget.otherUserId != null) {
        final res = await http.get(
          Uri.parse(
              '${ApiConstants.baseUrl}/profiles/${widget.otherUserId}/'),
          headers: {'Authorization': 'Token $token'},
        );

        if (res.statusCode == 200) {
          setState(() {
            _profileData =
            Map<String, dynamic>.from(jsonDecode(res.body));
          });
        }
      } else {
        final res = await http.get(
          Uri.parse(
              '${ApiConstants.baseUrl}/groups/${widget.chatRoomId}/'),
          headers: {'Authorization': 'Token $token'},
        );

        if (res.statusCode == 200) {
          setState(() {
            _profileData =
            Map<String, dynamic>.from(jsonDecode(res.body));
          });
        }
      }
    } catch (_) {}
  }

  void _showImagePreview() {
    if (_profileData == null) return;

    final imageUrl = widget.chatType == ChatType.private
        ? _profileData!['profile_image']
        : _profileData!['image'];

    if (imageUrl == null) return;

    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) {
        List<Widget> children = [];

        children.add(
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: CachedNetworkImage(
              imageUrl: imageUrl,
              width: double.infinity,
              height: 300,
              fit: BoxFit.cover,
            ),
          ),
        );

        children.add(const SizedBox(height: 14));

        children.add(
          Text(
            widget.title ??
                widget.otherUsername ??
                'Profile',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        );

        if (widget.chatType == ChatType.private) {
          children.add(const SizedBox(height: 12));

          children.add(
            IconButton(
              icon: const Icon(
                Icons.person,
                color: Color(0xFF00FF7F),
                size: 32,
              ),
              onPressed: () {
                Navigator.pop(context);

                if (widget.otherUserId != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          ProfileScreen(
                            userId: widget.otherUserId!,
                          ),
                    ),
                  );
                }
              },
            ),
          );
        }

        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(16),
          child: Stack(
            children: [
              BackdropFilter(
                filter: ImageFilter.blur(
                    sigmaX: 6, sigmaY: 6),
                child: Container(
                  color:
                  Colors.black.withOpacity(0.5),
                ),
              ),
              Center(
                child: Container(
                  width: MediaQuery.of(context)
                      .size
                      .width *
                      0.85,
                  padding:
                  const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius:
                    BorderRadius.circular(20),
                    border: Border.all(
                      color:
                      const Color(0xFF00FF7F),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    mainAxisSize:
                    MainAxisSize.min,
                    children: children,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    _messagesRef.push().set({
      'type': 'text',
      'senderId': myUserId,
      'text': text,
      'timestamp': ServerValue.timestamp,
    });

    _controller.clear();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(
        const Duration(milliseconds: 150),
            () {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController
                  .position.maxScrollExtent,
              duration:
              const Duration(milliseconds: 250),
              curve: Curves.easeOut,
            );
          }
        });
  }

  @override
  Widget build(BuildContext context) {
    String? imageUrl;

    if (_profileData != null) {
      if (widget.chatType == ChatType.private) {
        imageUrl = _profileData!['profile_image'];
      } else {
        imageUrl = _profileData!['image'];
      }
    }
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        titleSpacing: 0,
        title: Row(
          children: [
            GestureDetector(
              onTap: _showImagePreview,
              child: CircleAvatar(
                radius: 22,
                backgroundColor:
                Colors.grey[800],
                backgroundImage:
                imageUrl != null
                    ? CachedNetworkImageProvider(
                    imageUrl)
                    : null,
                child: imageUrl == null
                    ? const Icon(Icons.person,
                    color:
                    Colors.white54)
                    : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                widget.title ??
                    widget.otherUsername ??
                    'Chat',
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight:
                    FontWeight.w600),
                overflow:
                TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child:
            StreamBuilder<DatabaseEvent>(
              stream: _messagesRef.onValue,
              builder:
                  (context, snapshot) {
                if (!snapshot.hasData ||
                    snapshot.data!
                        .snapshot.value ==
                        null) {
                  return const Center(
                    child: Text(
                      'No messages yet',
                      style: TextStyle(
                          color:
                          Colors.white54),
                    ),
                  );
                }

                final raw =
                snapshot.data!
                    .snapshot.value
                as Map<dynamic,
                    dynamic>;

                final messages = raw.values
                    .map<
                    Map<String,
                        dynamic>>(
                        (e) =>
                    Map<String,
                        dynamic>.from(
                        e))
                    .toList()
                  ..sort((a, b) =>
                      (a['timestamp'] ??
                          0)
                          .compareTo(
                          b['timestamp'] ??
                              0));

                _scrollToBottom();

                return ListView.builder(
                  controller:
                  _scrollController,
                  itemCount:
                  messages.length,
                  itemBuilder:
                      (_, i) {
                    final msg =
                    messages[i];
                    final bool isMe =
                        msg['senderId'] ==
                            myUserId;

                    if (msg['type'] ==
                        'post' &&
                        msg['post'] !=
                            null) {
                      final post =
                      Map<String,
                          dynamic>.from(
                          msg['post']);

                      return ChatPostBubble(
                        postPreview:
                        post,
                        isMe: isMe,
                        onTap: () {
                          showModalBottomSheet(
                            context:
                            context,
                            isScrollControlled:
                            true,
                            backgroundColor:
                            Colors
                                .transparent,
                            builder:
                                (_) =>
                                PostDetailModal(
                                  post:
                                  post,
                                  heroTag:
                                  'chat_post_${post['id']}',
                                ),
                          );
                        },
                      );
                    }

                    return _textBubble(
                        msg['text']
                            ?.toString() ??
                            '',
                        isMe);
                  },
                );
              },
            ),
          ),
          Container(
            padding:
            const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 6),
            color: Colors.black,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller:
                    _controller,
                    style: const TextStyle(
                        color:
                        Colors.white),
                    decoration:
                    InputDecoration(
                      hintText:
                      'Type a message...',
                      hintStyle:
                      const TextStyle(
                          color: Colors
                              .white54),
                      filled: true,
                      fillColor:
                      Colors.grey[900],
                      border:
                      OutlineInputBorder(
                        borderRadius:
                        BorderRadius
                            .circular(
                            20),
                        borderSide:
                        BorderSide
                            .none,
                      ),
                      contentPadding:
                      const EdgeInsets
                          .symmetric(
                        horizontal:
                        16,
                        vertical:
                        10,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.send,
                    color: Color(
                        0xFF00FF7F),
                  ),
                  onPressed:
                  _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _textBubble(
      String text, bool isMe) {
    return Align(
      alignment: isMe
          ? Alignment.centerRight
          : Alignment.centerLeft,
      child: Container(
        margin:
        const EdgeInsets.symmetric(
            vertical: 4,
            horizontal: 8),
        padding:
        const EdgeInsets.all(12),
        constraints: BoxConstraints(
          maxWidth:
          MediaQuery.of(context)
              .size
              .width *
              0.75,
        ),
        decoration: BoxDecoration(
          color: isMe
              ? const Color(
              0xFF00FF7F)
              : Colors.grey[800],
          borderRadius:
          BorderRadius.circular(
              10),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isMe
                ? Colors.black
                : Colors.white,
          ),
        ),
      ),
    );
  }
}
