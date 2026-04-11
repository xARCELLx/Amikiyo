// lib/src/screens/chat/chat_screen.dart
// PRODUCTION CHAT ENGINE — PART 1 (CORE + PAGINATION)

import 'dart:async';
import 'dart:convert';
import 'dart:ui';


import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:http/http.dart' as http;

import '../../services/constants.dart';
import '../../services/storage_service.dart';
import '../group/group_about_screen.dart';
import '../profile/profile_screen.dart';
import 'widgets/chat_post_bubble.dart';
import '../profile/post_detail_modal.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
enum ChatType { private, group }

/// ─────────────────────────────────────────────────────────────
/// MESSAGE MODEL
/// ─────────────────────────────────────────────────────────────

class ChatMessage {
  final String? senderUsername;
  final String id;
  final int senderId;
  final String type; // text | post
  final String? content;
  final int? postId;
  final int timestamp;
  final String? replyTo;
  final bool deletedForEveryone;
  final Map<String, dynamic>? deletedFor;
  final Map<String, dynamic>? seenBy;
  final String? imageUrl;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.type,
    required this.timestamp,
    this.content,
    this.postId,
    this.replyTo,
    this.deletedForEveryone = false,
    this.deletedFor,
    this.seenBy,
    this.senderUsername,
    this.imageUrl,
  });

  factory ChatMessage.fromSnapshot(DataSnapshot snap) {
    final data = Map<String, dynamic>.from(snap.value as Map);

    return ChatMessage(
      imageUrl: data['imageUrl'],
      id: snap.key!,
      senderId: data['senderId'] ?? 0,
      senderUsername: data['senderUsername'],
      type: data['type'] ?? 'text',
      content: data['content'],
      postId: data['postId'],
      timestamp: data['timestamp'] ?? 0,
      replyTo: data['replyTo'],
      deletedForEveryone: data['deletedForEveryone'] ?? false,
      deletedFor: data['deletedFor'] != null
          ? Map<String, dynamic>.from(data['deletedFor'])
          : null,
      seenBy: data['seenBy'] != null
          ? Map<String, dynamic>.from(data['seenBy'])
          : null,
    );
  }
}

/// ─────────────────────────────────────────────────────────────
/// CHAT SCREEN
/// ─────────────────────────────────────────────────────────────

class ChatScreen extends StatefulWidget {
  final String chatRoomId;
  final ChatType chatType;
  final int? otherUserId;
  final String? title;


  const ChatScreen({
    Key? key,
    required this.chatRoomId,
    required this.chatType,
    this.otherUserId,
    this.title,
  }) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  /// CONTROLLERS
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isInitialized = false;

  /// FIREBASE
  late DatabaseReference _chatRef;
  Query? _messagesQuery;
  StreamSubscription<DatabaseEvent>? _childAddedSub;
  StreamSubscription<DatabaseEvent>? _childChangedSub;

  /// STATE
  List<ChatMessage> _messages = [];
  Map<int, Map<String, dynamic>> _postCache = {};
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int? _oldestTimestamp;
  ChatMessage? _replyingTo;

  late int myUserId;
  String? _headerImage;
  String? _headerTitle;
  /// PAGINATION CONFIG
  static const int pageSize = 25;
  bool _isCurrentUserAdmin = false;

  String? _buildImageUrl(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) return null;

    if (imagePath.startsWith('http')) {
      return imagePath;
    }

    return "${ApiConstants.baseUrl}$imagePath";
  }

  /// ───────────────── INIT ─────────────────

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    if (widget.chatType == ChatType.group) {
      final token = await StorageService.getToken();

      final res = await http.post(
        Uri.parse(
            '${ApiConstants.baseUrl}/groups/${widget.chatRoomId}/validate/'),
        headers: {'Authorization': 'Token $token'},
      );
      if (widget.chatType == ChatType.group) {
        await _loadAdminStatus();
      }

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['allowed'] != true) {
          if (mounted) Navigator.pop(context);
          return;
        }
      }
    }
    myUserId = await StorageService.getUserId() ?? 0;

    _chatRef =
        FirebaseDatabase.instance.ref('chats/${widget.chatRoomId}');

    await _ensureChatMetadata();

    _setupInitialQuery();

    _scrollController.addListener(_handleScroll);
    await _loadHeaderData();
    await _chatRef.child('unreadCount/$myUserId').set(0);
    setState(() {
      _isInitialized = true;
    });
  }
  Future<void> _loadAdminStatus() async {
    try {
      final token = await StorageService.getToken();
      if (token == null) return;

      final res = await http.get(
        Uri.parse(
            '${ApiConstants.baseUrl}/groups/${widget.chatRoomId}/'),
        headers: {'Authorization': 'Token $token'},
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);

        final members = data['members'] ?? [];

        for (final m in members) {
          if (m['user_id'] == myUserId &&
              m['role'] == 'admin') {
            setState(() {
              _isCurrentUserAdmin = true;
            });
            break;
          }
        }
      }
    } catch (_) {}
  }
  Future<void> _loadHeaderData() async {
    final token = await StorageService.getToken();
    if (token == null) return;

    try {
      if (widget.chatType == ChatType.private &&
          widget.otherUserId != null) {

        final res = await http.get(
          Uri.parse(
              '${ApiConstants.baseUrl}/profiles/${widget.otherUserId}/'),
          headers: {'Authorization': 'Token $token'},
        );

        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          setState(() {
            _headerTitle = data['username'];
            _headerImage = data['profile_image'];
          });
        }
      }

      if (widget.chatType == ChatType.group) {
        final res = await http.get(
          Uri.parse('${ApiConstants.baseUrl}/groups/${widget.chatRoomId}/'),
          headers: {'Authorization': 'Token $token'},
        );

        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          setState(() {
            _headerTitle = data['name'];
            _headerImage = _buildImageUrl(data['image']);
          });
        }
      }
    } catch (_) {}
  }

  /// Ensure chat root exists
  Future<void> _ensureChatMetadata() async {
    final snap = await _chatRef.get();

    if (!snap.exists) {
      await _chatRef.set({
        "type": widget.chatType.name,
        "createdAt": ServerValue.timestamp,
      });
    }
  }

  /// ───────────────── INITIAL QUERY ─────────────────

  void _setupInitialQuery() {
    _messagesQuery = _chatRef
        .child('messages')
        .orderByChild('timestamp')
        .limitToLast(pageSize);

    _childAddedSub =
        _messagesQuery!.onChildAdded.listen(_onMessageAdded);

    _childChangedSub =
        _chatRef.child('messages').onChildChanged.listen(_onMessageChanged);
  }

  void _onMessageAdded(DatabaseEvent event) {
    final message = ChatMessage.fromSnapshot(event.snapshot);

    if (_messages.any((m) => m.id == message.id)) return;

    setState(() {
      _messages.add(message);
      _messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    });

    _oldestTimestamp ??= message.timestamp;

    if (_messages.length < pageSize) {
      _hasMore = false;
    }
    if (widget.chatType == ChatType.private &&
        message.senderId != myUserId) {
      _chatRef
          .child('messages/${message.id}/seenBy/$myUserId')
          .set(true);
    }

    _scrollToBottom();
  }

  void _onMessageChanged(DatabaseEvent event) {
    final updated = ChatMessage.fromSnapshot(event.snapshot);

    final index = _messages.indexWhere((m) => m.id == updated.id);

    if (index != -1) {
      setState(() {
        _messages[index] = updated;
      });
    }
  }

  /// ───────────────── PAGINATION ─────────────────

  void _handleScroll() {
    if (_scrollController.position.pixels <= 100 &&
        !_isLoadingMore &&
        _hasMore) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    if (_oldestTimestamp == null) return;

    setState(() => _isLoadingMore = true);

    final query = _chatRef
        .child('messages')
        .orderByChild('timestamp')
        .endAt(_oldestTimestamp! - 1)
        .limitToLast(pageSize);

    final snap = await query.get();

    if (!snap.exists || snap.value == null) {
      _hasMore = false;
      setState(() => _isLoadingMore = false);
      return;
    }

    final raw = Map<String, dynamic>.from(snap.value as Map);

    final List<ChatMessage> olderMessages = [];

    raw.forEach((key, value) {
      final data = Map<String, dynamic>.from(value);

      olderMessages.add(
        ChatMessage(
          id: key,
          senderId: data['senderId'] ?? 0,
          senderUsername: data['senderUsername'],
          type: data['type'] ?? 'text',
          content: data['content'],
          postId: data['postId'],
          timestamp: data['timestamp'] ?? 0,
          replyTo: data['replyTo'],
          deletedForEveryone: data['deletedForEveryone'] ?? false,
          deletedFor: data['deletedFor'] != null
              ? Map<String, dynamic>.from(data['deletedFor'])
              : null,
          seenBy: data['seenBy'] != null
              ? Map<String, dynamic>.from(data['seenBy'])
              : null,
        ),
      );
    });

    olderMessages.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    setState(() {
      _messages.insertAll(0, olderMessages);
      _oldestTimestamp = _messages.first.timestamp;
      _isLoadingMore = false;
    });
  }

  /// ───────────────── SEND TEXT ─────────────────

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final msgRef = _chatRef.child('messages').push();

    final myUsername = widget.chatType == ChatType.private
        ? widget.title ?? ''
        : await StorageService.getUsername();

    final timestamp = ServerValue.timestamp;

    await msgRef.set({
      "senderId": myUserId,
      "senderUsername": myUsername,
      "type": "text",
      "content": text,
      "timestamp": timestamp,
      "replyTo": _replyingTo?.id,
      "deletedForEveryone": false,
    });

    /// 🔥 METADATA UPDATE
    await _chatRef.child('metadata').update({
      "lastMessage": text,
      "lastMessageType": "text",
      "lastMessageTime": timestamp,
      "lastSenderId": myUserId,
    });

    /// 🔥 UNREAD COUNT UPDATE
    final participantsSnap =
    await _chatRef.child('participants').get();

    if (participantsSnap.exists) {
      final participants =
      Map<String, dynamic>.from(participantsSnap.value as Map);

      for (final userId in participants.keys) {
        if (int.parse(userId) != myUserId) {
          final current = await _chatRef
              .child('unreadCount/$userId')
              .get();

          int count = current.exists ? current.value as int : 0;

          await _chatRef
              .child('unreadCount/$userId')
              .set(count + 1);
        }
      }
    }

    /// RESET MY UNREAD
    await _chatRef.child('unreadCount/$myUserId').set(0);

    /// STOP TYPING
    await _chatRef.child('typing/$myUserId').set(false);

    _controller.clear();
    _cancelReply();
  }

  Future<void> _sendImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);

    if (picked == null) return;

    final file = File(picked.path);

    final fileName = DateTime.now().millisecondsSinceEpoch.toString();

    final ref = FirebaseStorage.instance
        .ref()
        .child('chat_images/${widget.chatRoomId}/$fileName.jpg');

    await ref.putFile(file);

    final imageUrl = await ref.getDownloadURL();

    final msgRef = _chatRef.child('messages').push();

    final username = await StorageService.getUsername();

    await msgRef.set({
      "senderId": myUserId,
      "senderUsername": username,
      "type": "image",
      "imageUrl": imageUrl,
      "timestamp": ServerValue.timestamp,
      "deletedForEveryone": false,
    });

    /// 🔥 UPDATE METADATA
    await _chatRef.child('metadata').update({
      "lastMessage": "📷 Image",
      "lastMessageType": "image",
      "lastMessageTime": ServerValue.timestamp,
      "lastSenderId": myUserId,
    });

    /// 🔥 RESET UNREAD
    await _chatRef.child('unreadCount/$myUserId').set(0);
  }

  void _setReply(ChatMessage message) {
    setState(() {
      _replyingTo = message;
    });
  }

  void _cancelReply() {
    setState(() {
      _replyingTo = null;
    });
  }
  Future<void> _deleteForMe(ChatMessage message) async {
    await _chatRef
        .child('messages/${message.id}/deletedFor/$myUserId')
        .set(true);
  }

  Future<void> _deleteForEveryone(ChatMessage message) async {
    await _chatRef
        .child('messages/${message.id}')
        .update({
      "deletedForEveryone": true,
    });
  }

  void _showMessageOptions(ChatMessage message) {
    final isMe = message.senderId == myUserId;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black,
      builder: (_) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.reply,
                    color: Color(0xFF00FF7F)),
                title: const Text("Reply",
                    style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  _setReply(message);
                },
              ),
              if (isMe || (widget.chatType == ChatType.group && _isCurrentUserAdmin))
                ListTile(
                  leading: const Icon(Icons.delete,
                      color: Colors.red),
                  title: const Text("Delete for everyone",
                      style: TextStyle(color: Colors.white)),
                  onTap: () async {
                    Navigator.pop(context);
                    await _deleteForEveryone(message);
                  },
                ),
              ListTile(
                leading:
                const Icon(Icons.delete_outline,
                    color: Colors.white70),
                title: const Text("Delete for me",
                    style: TextStyle(color: Colors.white)),
                onTap: () async {
                  Navigator.pop(context);
                  await _deleteForMe(message);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _fetchPost(int postId) async {
    if (_postCache.containsKey(postId)) return;

    try {
      final token = await StorageService.getToken();
      if (token == null) return;

      final res = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/posts/$postId/detail/'),
        headers: {'Authorization': 'Token $token'},
      );

      if (res.statusCode == 200) {
        setState(() {
          _postCache[postId] =
          Map<String, dynamic>.from(jsonDecode(res.body));
        });
      }
    } catch (_) {}
  }

  void _openHeaderTarget() {
    if (widget.chatType == ChatType.private &&
        widget.otherUserId != null) {

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProfileScreen(
            userId: widget.otherUserId,
          ),
        ),
      );
    }

    if (widget.chatType == ChatType.group) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => GroupAboutScreen(
            groupId: widget.chatRoomId,
          ),
        ),
      );
    }
  }

  /// ───────────────── UI ─────────────────

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(
            color: Color(0xFF00FF7F),
          ),
        ),
      );
    }
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
          title: GestureDetector(
            onTap: _openHeaderTarget,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.grey[800],
                  backgroundImage: (_headerImage != null &&
                      _headerImage!.startsWith('http'))
                      ? NetworkImage(_headerImage!)
                      : null,
                  child: _headerImage == null
                      ? const Icon(Icons.person, size: 18, color: Colors.white54)
                      : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _headerTitle ?? widget.title ?? "Chat",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
      ),
      body: Column(
        children: [
          StreamBuilder(
            stream: _chatRef.child('typing').onValue,
            builder: (context, snap) {
              if (!snap.hasData || snap.data!.snapshot.value == null) {
                return const SizedBox();
              }

              final typing =
              Map<String, dynamic>.from(snap.data!.snapshot.value as Map);

              typing.remove(myUserId.toString());

              if (typing.isEmpty) return const SizedBox();

              return Padding(
                padding: const EdgeInsets.all(8),
                child: Text(
                  "Typing...",
                  style: TextStyle(color: Colors.white54),
                ),
              );
            },
          ),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: _messages.length,
              itemBuilder: (_, i) {
                final msg = _messages[i];
                final isMe = msg.senderId == myUserId;

                if (msg.deletedForEveryone) {
                  return _deletedBubble();
                }

                if (msg.deletedFor != null &&
                    msg.deletedFor![myUserId.toString()] == true) {
                  return const SizedBox();
                }

                if (msg.type == 'image' && msg.imageUrl != null) {
                  return GestureDetector(
                    onLongPress: () => _showMessageOptions(msg),
                    child: Align(
                      alignment: isMe
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child:Hero(
                            tag: msg.imageUrl!,
                            child: Image.network(
                              msg.imageUrl!,
                              width: 200,
                              height: 200,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }

                if (msg.type == 'text') {
                  return _textBubble(msg, isMe);
                }

                if (msg.type == 'post' && msg.postId != null) {
                  _fetchPost(msg.postId!);

                  final post = _postCache[msg.postId!];

                  if (post == null) {
                    return const Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(
                        color: Color(0xFF00FF7F),
                      ),
                    );
                  }

                  return GestureDetector(
                    onLongPress: () => _showMessageOptions(msg),
                    onTap: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => PostDetailModal(
                        post: post,
                        heroTag: "chat_post_${msg.postId}",
                      ),
                    );
                  },
                      child: ChatPostBubble(
                        post: post,
                        isMe: isMe,
                        senderUsername:
                        (widget.chatType == ChatType.group || !isMe)
                            ? msg.senderUsername
                            : null,
                        replyPreview: msg.replyTo != null
                            ? _buildReplyPreview(msg.replyTo!)
                            : null,

                        // 🔥 READ RECEIPT LOGIC
                        showReadReceipt:
                        isMe && widget.chatType == ChatType.private,

                        isSeen:
                        msg.seenBy != null &&
                            widget.otherUserId != null &&
                            msg.seenBy![widget.otherUserId.toString()] == true,
                      ),
                  );
                }

                return const SizedBox();
              },
            ),
          ),
          _inputBar(),
        ],
      ),
    );
  }



  Widget _buildReplyPreview(String replyId) {
    final repliedMessage =
    _messages.firstWhere(
          (m) => m.id == replyId,
      orElse: () => ChatMessage(
        id: '',
        senderId: 0,
        type: 'text',
        timestamp: 0,
        content: 'Message unavailable',
      ),
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        repliedMessage.content ?? '',
        style: const TextStyle(
          fontSize: 12,
          color: Colors.white70,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _textBubble(ChatMessage message, bool isMe) {
    final text = message.content ?? '';

    // 🔥 Deleted for everyone
    if (message.deletedForEveryone) {
      return _deletedBubble();
    }

    // 🔥 Deleted for me
    if (message.deletedFor != null &&
        message.deletedFor![myUserId.toString()] == true) {
      return const SizedBox();
    }

    return GestureDetector(
      onLongPress: () => _showMessageOptions(message),
      child: Align(
        alignment:
        isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          padding: const EdgeInsets.all(12),
          constraints: BoxConstraints(
              maxWidth:
              MediaQuery.of(context).size.width * 0.75),
          decoration: BoxDecoration(
            color: isMe
                ? const Color(0xFF00FF7F)
                : Colors.grey[800],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // 🔥 REPLY PREVIEW
              if (message.replyTo != null)
                _buildReplyPreview(message.replyTo!),

              // 🔥 USERNAME (Group OR Private Other User)
          if (widget.chatType == ChatType.group || !isMe)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: GestureDetector(
                onTap: () {
                if (widget.chatType == ChatType.group &&
                    message.senderId != myUserId) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProfileScreen(
                        userId: message.senderId,
                        ),
                      ),
                    );
                }
                },
                child: Text(
                message.senderUsername ?? "User",
                style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: isMe
                ? Colors.black.withOpacity(0.7)
                    : const Color(0xFF00FF7F),
                ),
                ),
                ),
          ),

              // 🔥 MESSAGE TEXT
              Text(
                text,
                style: TextStyle(
                  color: isMe ? Colors.black : Colors.white,
                ),
              ),

              // 🔥 READ RECEIPT (PRIVATE CHAT ONLY)
              if (isMe && widget.chatType == ChatType.private)
                Align(
                  alignment: Alignment.bottomRight,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      (
                          message.seenBy != null &&
                              widget.otherUserId != null &&
                              message.seenBy![
                              widget.otherUserId.toString()] == true
                      )
                          ? "✓✓"
                          : "✓",
                      style: const TextStyle(
                        fontSize: 15,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _deletedBubble() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 6),
      child: Center(
        child: Text(
          "Message deleted",
          style: TextStyle(
            color: Colors.white38,
            fontStyle: FontStyle.italic,
          ),
        ),
      ),
    );
  }

  Widget _inputBar() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_replyingTo != null)
          Container(
            color: Colors.grey[900],
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 8),
            child: Row(
              children: [
                const Icon(Icons.reply,
                    size: 16,
                    color: Color(0xFF00FF7F)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _replyingTo!.content ?? '',
                    style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close,
                      color: Colors.white54),
                  onPressed: _cancelReply,
                )
              ],
            ),
          ),
        Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 10, vertical: 6),
          color: Colors.black,
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  onChanged: (value) {
                    _chatRef.child('typing/$myUserId').set(true);

                    Future.delayed(const Duration(seconds: 1), () {
                      _chatRef.child('typing/$myUserId').set(false);
                    });
                  },
                  style:
                  const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: "Type message...",
                    hintStyle: const TextStyle(
                        color: Colors.white54),
                    filled: true,
                    fillColor: Colors.grey[900],
                    border: OutlineInputBorder(
                      borderRadius:
                      BorderRadius.circular(20),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.image, color: Color(0xFF00FF7F)),
                onPressed: _sendImage,
              ),
              IconButton(
                icon: const Icon(Icons.send,
                    color: Color(0xFF00FF7F)),
                onPressed: _sendMessage,
              )
            ],
          ),
        ),
      ],
    );
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 200), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _childAddedSub?.cancel();
    _childChangedSub?.cancel();
    _scrollController.dispose();
    super.dispose();
  }
}