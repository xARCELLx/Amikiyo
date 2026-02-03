// lib/src/screens/home/widgets/bottom_nav_bar.dart

import 'package:flutter/material.dart';
import 'package:amikiyo/src/screens/home/home_screen.dart';
import 'package:amikiyo/src/screens/groups/group_screen.dart';
import 'package:amikiyo/src/screens/chat/chat_list_screen.dart';
import 'package:amikiyo/src/screens/profile/profile_screen.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
  });

  /// ✅ SAFE TAB NAVIGATION
  /// - Clears stacked routes
  /// - Keeps app alive
  /// - Prevents app exit on back
  void _switchTab(BuildContext context, Widget screen) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => screen),
          (route) => route.isFirst,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      type: BottomNavigationBarType.fixed,
      backgroundColor: Colors.black,
      selectedItemColor: const Color(0xFF00FF7F),
      unselectedItemColor: Colors.white54,
      showUnselectedLabels: true,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.group),
          label: 'Groups',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.chat),
          label: 'Chat',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
      onTap: (index) {
        if (index == currentIndex) return;

        switch (index) {
          case 0:
            _switchTab(context, const HomeScreen());
            break;

          case 1:
            _switchTab(context, const GroupsScreen());
            break;

          case 2:
          /// ✅ CHAT LIST stays inside bottom nav
            _switchTab(context, const ChatListScreen());
            break;

          case 3:
            _switchTab(context, const ProfileScreen());
            break;
        }
      },
    );
  }
}
