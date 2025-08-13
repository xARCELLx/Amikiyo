import 'package:flutter/material.dart';
import 'package:amikiyo/src/screens/home/widgets/app_bar.dart';
import 'package:amikiyo/src/screens/home/widgets/bottom_nav_bar.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: customAppBar(context, title: 'Chat'),
      body: const Center(child: Text('Chat Screen - Work in Progress')),
      bottomNavigationBar: BottomNavBar(currentIndex: 2),
    );
  }
}