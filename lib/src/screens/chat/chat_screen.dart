import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatScreen extends StatefulWidget {
  final String chatRoomId;     // UUID from Django
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
  final int myUserId = FirebaseAuth.instance.currentUser!.uid.hashCode;

  @override
  void initState() {
    super.initState();

    _messagesRef = FirebaseDatabase.instance
        .ref('chats/${widget.chatRoomId}/messages');
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    _messagesRef.push().set({
      'senderId': myUserId,
      'text': text,
      'timestamp': ServerValue.timestamp,
    });

    _controller.clear();
    _scrollToBottom();
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
          /// MESSAGES
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

                final data =
                snapshot.data!.snapshot.value as Map<dynamic, dynamic>;

                final messages = data.entries.toList()
                  ..sort((a, b) {
                    final ta = a.value['timestamp'] ?? 0;
                    final tb = b.value['timestamp'] ?? 0;
                    return ta.compareTo(tb);
                  });

                _scrollToBottom();

                return ListView.builder(
                  controller: _scrollController,
                  itemCount: messages.length,
                  itemBuilder: (_, i) {
                    final msg = messages[i].value;
                    final isMe = msg['senderId'] == myUserId;

                    return Align(
                      alignment:
                      isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                            vertical: 4, horizontal: 8),
                        padding: const EdgeInsets.all(12),
                        constraints: BoxConstraints(
                            maxWidth:
                            MediaQuery.of(context).size.width * 0.75),
                        decoration: BoxDecoration(
                          color: isMe
                              ? const Color(0xFF00FF7F)
                              : Colors.grey[800],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          msg['text'] ?? '',
                          style: TextStyle(
                            color: isMe ? Colors.black : Colors.white,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          /// INPUT
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
                          horizontal: 16, vertical: 10),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send,
                      color: Color(0xFF00FF7F)),
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
