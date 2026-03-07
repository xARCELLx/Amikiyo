import 'package:flutter/material.dart';

import '../home/feed_screen.dart';
import '../../models/story_model.dart';
import '../../services/story_service.dart';
import '../../widgets/story/story_list.dart';

import 'widgets/app_bar.dart';
import 'widgets/bottom_nav_bar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  List<StoryUser> _stories = [];
  bool _loadingStories = true;

  @override
  void initState() {
    super.initState();
    _loadStories();
  }

  // ───────────────── LOAD STORIES ─────────────────

  Future<void> _loadStories() async {

    if (!mounted) return;

    setState(() {
      _loadingStories = true;
    });

    try {

      final stories = await StoryService.fetchStoryFeed();

      if (!mounted) return;

      setState(() {
        _stories = stories;
      });

    } catch (e) {

      debugPrint("Story load error: $e");

    }

    if (!mounted) return;

    setState(() {
      _loadingStories = false;
    });
  }

  // ───────────────── UI ─────────────────

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Colors.black,

      // AppBar
      appBar: customAppBar(context, title: 'Amikiyo'),

      // Bottom Navigation
      bottomNavigationBar: const BottomNavBar(currentIndex: 0),

      body: Column(
        children: [

          // ───────── STORIES ROW ─────────

          SizedBox(
            height: 110,
            child: _loadingStories
                ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF00FF7F),
              ),
            )
                : StoryList(
              stories: _stories,
              refreshStories: _loadStories, // 🔥 IMPORTANT
            ),
          ),

          const Divider(
            height: 1,
            color: Colors.white10,
          ),

          // ───────── POSTS FEED ─────────

          const Expanded(
            child: FeedScreen(),
          ),

        ],
      ),
    );
  }
}