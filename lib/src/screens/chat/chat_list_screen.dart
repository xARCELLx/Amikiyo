import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../services/storage_service.dart';
import '../../services/constants.dart';
import 'chat_screen.dart';
import '../home/widgets/bottom_nav_bar.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  bool isLoading = true;
  List<Map<String, dynamic>> chats = [];

  @override
  void initState() {
    super.initState();
    _loadChats();
  }

  Future<void> _loadChats() async {
    setState(() => isLoading = true);

    try {
      final token = await StorageService.getToken();
      if (token == null) return;

      final res = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/chat/my/'),
        headers: {'Authorization': 'Token $token'},
      );

      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        chats = data.cast<Map<String, dynamic>>();
      }
    } catch (_) {}

    if (!mounted) return;
    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'Chats',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: isLoading
          ? const Center(
        child: CircularProgressIndicator(color: Color(0xFF00FF7F)),
      )
          : chats.isEmpty
          ? const Center(
        child: Text(
          'No chats yet',
          style: TextStyle(color: Colors.white70),
        ),
      )
          : ListView.builder(
        itemCount: chats.length,
        itemBuilder: (_, i) {
          final chat = chats[i];
          final other = chat['other_user'];

          return ListTile(
            leading: const CircleAvatar(
              backgroundColor: Color(0xFF00FF7F),
              child: Icon(Icons.person, color: Colors.black),
            ),
            title: Text(
              other['username'],
              style: const TextStyle(color: Colors.white),
            ),
            subtitle: const Text(
              'Tap to chat',
              style: TextStyle(color: Colors.white54),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChatScreen(
                    chatRoomId: chat['id'], // UUID
                    otherUserId: other['id'],
                    otherUsername: other['username'],
                  ),
                ),
              );
            },
          );
        },
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 2),
    );
  }
}
