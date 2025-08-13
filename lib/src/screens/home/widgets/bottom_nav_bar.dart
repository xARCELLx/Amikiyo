import 'package:flutter/material.dart';
import 'package:amikiyo/src/screens/home/home_screen.dart';
import 'package:amikiyo/src/screens/groups/group_screen.dart';
import 'package:amikiyo/src/screens/chat/chat_screen.dart';
import 'package:amikiyo/src/screens/profile/profile_screen.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  const BottomNavBar({super.key, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      type: BottomNavigationBarType.fixed,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.group), label: 'Groups'),
        BottomNavigationBarItem(icon: Icon(Icons.chat

        ), label: 'Chat'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
      ],
      onTap: (index) {
        switch (index) {
          case 0:
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const HomeScreen()));
            break;
          case 1:
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const GroupsScreen()));
            break;
          case 2:
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ChatScreen()));
            break;
          case 3:
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ProfileScreen()));
            break;
        }
      },
    );
  }
}