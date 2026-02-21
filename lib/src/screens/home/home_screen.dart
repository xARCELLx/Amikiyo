import 'package:flutter/material.dart';

import '../home/feed_screen.dart';
import 'widgets/app_bar.dart';
import 'widgets/bottom_nav_bar.dart';

import 'widgets/trending_banner.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();


  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }


  // ───────────────── MAIN BUILD ─────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,

      // 🔥 AppBar with Search
      appBar:customAppBar(context, title:'Amikiyo'),


      // 🔥 Bottom Navigation
      bottomNavigationBar: const BottomNavBar(currentIndex: 0),

      // 🔥 Body
      body: Column(
        children: [

          // Trending Banner stays on top
          const TrendingBanner(),

          // REAL FEED ENGINE EMBEDDED HERE
          const Expanded(
            child: FeedScreen(),
          ),
        ],
      ),
    );
  }
}
