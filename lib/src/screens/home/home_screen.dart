import 'package:flutter/material.dart';
import 'package:amikiyo/src/screens/home/widgets/app_bar.dart';
import 'package:amikiyo/src/screens/home/widgets/bottom_nav_bar.dart';
import 'package:amikiyo/src/screens/home/widgets/fab.dart';
import 'widgets/post_card.dart';
import 'widgets/trending_banner.dart';
import 'widgets/empty_feed.dart';
import '../../services/mock_data.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final posts = getMockPosts();
    return Scaffold(
      appBar: customAppBar(context, title: 'Amikiyo'),
      body: Column(
        children: [
          const TrendingBanner(),
          Expanded(
            child: posts.isEmpty
                ? const EmptyFeed()
                : ListView.builder(
              padding: const EdgeInsets.only(top: 8, bottom: 16),
              itemCount: posts.length,
              itemBuilder: (context, index) => PostCard(post: posts[index]),
            ),
          ),
        ],
      ),
      floatingActionButton: customFAB(context),
      bottomNavigationBar: BottomNavBar(currentIndex: 0),
    );
  }
}