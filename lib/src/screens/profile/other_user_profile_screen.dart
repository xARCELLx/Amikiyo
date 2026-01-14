// lib/src/screens/profile/other_user_profile_screen.dart

import 'dart:convert';
import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../config/constants.dart';
import '../../services/constants.dart';
import '../../services/storage_service.dart';
import '../home/widgets/bottom_nav_bar.dart';
import 'board_card.dart';
import 'post_detail_modal.dart';

class OtherUserProfileScreen extends StatefulWidget {
  final int userId;

  const OtherUserProfileScreen({
    super.key,
    required this.userId,
  });

  @override
  State<OtherUserProfileScreen> createState() =>
      _OtherUserProfileScreenState();
}

class _OtherUserProfileScreenState
    extends State<OtherUserProfileScreen>
    with SingleTickerProviderStateMixin {
  Map<String, dynamic>? profileData;
  List<dynamic> posts = [];
  bool isLoading = true;
  String error = '';

  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnimation =
        CurvedAnimation(parent: _controller, curve: Curves.easeIn);

    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      isLoading = true;
      error = '';
    });

    try {
      final token = await StorageService.getToken();

      final profileRes = await http.get(
        Uri.parse(
            '${ApiConstants.baseUrl}/profiles/${widget.userId}/'),
        headers: {'Authorization': 'Token $token'},
      );

      if (profileRes.statusCode != 200) {
        setState(() {
          error = 'User not found';
          isLoading = false;
        });
        return;
      }

      final profileJson = jsonDecode(profileRes.body);

      final postsRes = await http.get(
        Uri.parse(
            '${ApiConstants.baseUrl}/posts/user/${widget.userId}/'),
        headers: {'Authorization': 'Token $token'},
      );

      final fetchedPosts =
      postsRes.statusCode == 200 ? jsonDecode(postsRes.body) : [];

      setState(() {
        profileData = profileJson;
        posts = fetchedPosts;
        isLoading = false;
      });

      _controller.forward();
    } catch (_) {
      setState(() {
        error = 'Network error';
        isLoading = false;
      });
    }
  }

  String _getRank(int watchedCount) {
    if (watchedCount >= 50) return 'Jonin';
    if (watchedCount >= 20) return 'Chunin';
    return 'Genin';
  }

  List<Map<String, dynamic>> _getUniqueAnime() {
    if (profileData == null) return [];

    final board = profileData!['anime_board'] ?? {};
    final all = [
      ...(board['top_three'] ?? []),
      ...(board['watched'] ?? []),
      ...(board['next_to_watch'] ?? []),
    ];

    final seen = <String>{};
    final unique = <Map<String, dynamic>>[];

    for (var anime in all) {
      final id = anime['id']?.toString();
      if (id != null && !seen.contains(id)) {
        seen.add(id);
        unique.add(Map<String, dynamic>.from(anime));
      }
    }
    return unique;
  }

  void _openPostDetail(int index) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PostDetailModal(
        post: posts[index],
        heroTag: 'other_post_$index',
        onDelete: () {}, // ❌ disabled
        onUpdate: () {},
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child:
          CircularProgressIndicator(color: Color(0xFF00FF7F)),
        ),
      );
    }

    if (error.isNotEmpty || profileData == null) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Text(error,
              style: const TextStyle(color: Colors.white)),
        ),
      );
    }

    final username = profileData!['username'] ?? 'Unknown';
    final bio = profileData!['bio'] ?? '';
    final profileImage = profileData!['profile_image'] ??
        Constants.defaultProfilePath;

    final board =
        profileData!['anime_board'] as Map<String, dynamic>? ?? {};

    final watchedCount =
        (board['watched'] as List?)?.length ?? 0;

    final postsCount = profileData!['posts_count'] ?? posts.length;
    final followersCount = profileData!['followers_count'] ?? 0;
    final followingCount = profileData!['following_count'] ?? 0;

    return Scaffold(
      extendBody: true,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Stack(
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF1E1E1E), Color(0xFF1A237E)],
                ),
              ),
            ),
            SafeArea(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// HEADER
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundImage:
                            CachedNetworkImageProvider(
                                profileImage),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [
                                Text(username,
                                    style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        fontFamily: 'AnimeAce')),
                                const SizedBox(height: 4),
                                Text(bio,
                                    style: const TextStyle(
                                        color: Colors.white70,
                                        fontFamily: 'AnimeAce')),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    /// ANIME BOARD (READ ONLY)
                    Padding(
                      padding:
                      const EdgeInsets.symmetric(horizontal: 16),
                      child: BoardCard(
                        topThree:
                        List.from(board['top_three'] ?? []),
                        watched: List.from(board['watched'] ?? []),
                        nextToWatch:
                        List.from(board['next_to_watch'] ?? []),
                      ),
                    ),

                    const SizedBox(height: 12),

                    /// RANK
                    Padding(
                      padding:
                      const EdgeInsets.symmetric(horizontal: 16),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                              color: const Color(0xFF00FF7F)),
                        ),
                        child: Text(
                          'Rank: ${_getRank(watchedCount)} ($watchedCount anime watched)',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    /// STATS
                    Padding(
                      padding:
                      const EdgeInsets.symmetric(horizontal: 16),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                              color: const Color(0xFF00FF7F)),
                        ),
                        child: Row(
                          mainAxisAlignment:
                          MainAxisAlignment.spaceAround,
                          children: [
                            _stat('$postsCount', 'Posts'),
                            _stat('$followersCount', 'Followers'),
                            _stat('$followingCount', 'Following'),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    /// POSTS GRID
                    Padding(
                      padding:
                      const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          const Text('Posts',
                              style: TextStyle(
                                  color: Color(0xFF00FF7F),
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          posts.isEmpty
                              ? const Center(
                              child: Text('No posts yet',
                                  style: TextStyle(
                                      color: Colors.white70)))
                              : GridView.builder(
                            shrinkWrap: true,
                            physics:
                            const NeverScrollableScrollPhysics(),
                            gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                            ),
                            itemCount: posts.length,
                            itemBuilder: (_, i) =>
                                GestureDetector(
                                  onTap: () =>
                                      _openPostDetail(i),
                                  child: Hero(
                                    tag: 'other_post_$i',
                                    child: ClipRRect(
                                      borderRadius:
                                      BorderRadius.circular(6),
                                      child: CachedNetworkImage(
                                        imageUrl: posts[i]['image'] ??
                                            Constants
                                                .placeholderImagePath,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar:
      const BottomNavBar(currentIndex: 0),
    );
  }

  Widget _stat(String v, String l) => Column(
    children: [
      Text(v,
          style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold)),
      Text(l, style: const TextStyle(color: Colors.white70)),
    ],
  );
}
