// lib/src/screens/profile/profile_screen.dart

import 'dart:convert';
import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../home/widgets/bottom_nav_bar.dart';
import '../../config/constants.dart';
import '../../services/api_service.dart';
import '../../services/storage_service.dart';
import '../../services/constants.dart';
import '../chat/chat_screen.dart';
import './board_card.dart';
import '../settings/settings_screen.dart';
import '../post_creation/create_post_screen.dart';
import 'post_detail_modal.dart';

class ProfileScreen extends StatefulWidget {
  /// null = my profile, non-null = other user
  final int? userId;

  const ProfileScreen({super.key, this.userId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;

  Map<String, dynamic>? profileData;
  List<dynamic> posts = [];
  bool isLoading = true;

  bool get isOwner => widget.userId == null;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnimation =
        CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _loadEverything();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // ───────────────── DATA LOADING ─────────────────

  Future<void> _loadEverything() async {
    if (!mounted) return;
    setState(() => isLoading = true);

    final token = await StorageService.getToken();
    if (token == null) return;

    try {
      // PROFILE
      if (isOwner) {
        profileData = await ApiService.getMyProfile();
      } else {
        final res = await http.get(
          Uri.parse('${ApiConstants.baseUrl}/profiles/${widget.userId}/'),
          headers: {'Authorization': 'Token $token'},
        );
        if (res.statusCode == 200) {
          profileData = jsonDecode(res.body);
        }
      }

      if (profileData == null) throw Exception();

      // POSTS (VISIBLE TO ALL)
      final postsUrl = isOwner
          ? '${ApiConstants.baseUrl}/posts/user/me/'
          : '${ApiConstants.baseUrl}/posts/user/${widget.userId}/';

      final postRes = await http.get(
        Uri.parse(postsUrl),
        headers: {'Authorization': 'Token $token'},
      );

      posts = postRes.statusCode == 200 ? jsonDecode(postRes.body) : [];

      if (!mounted) return;
      setState(() => isLoading = false);
      _controller.forward();
    } catch (_) {
      if (!mounted) return;
      setState(() => isLoading = false);
    }
  }

  // ───────────────── HELPERS ─────────────────

  List<Map<String, dynamic>> _getUniqueAnime() {
    final board = profileData?['anime_board'] ?? {};
    final List all = [
      ...(board['top_three'] ?? []),
      ...(board['watched'] ?? []),
      ...(board['next_to_watch'] ?? []),
    ];

    final seen = <String>{};
    final unique = <Map<String, dynamic>>[];

    for (final anime in all) {
      if (anime is Map<String, dynamic>) {
        final id = anime['id']?.toString();
        if (id != null && !seen.contains(id)) {
          seen.add(id);
          unique.add(anime);
        }
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
        heroTag: 'post_$index',
        onDelete: isOwner
            ? () {
          if (!mounted) return;
          setState(() => posts.removeAt(index));
        }
            : () {}, // ✅ NEVER NULL
        onUpdate: isOwner ? _loadEverything : () {}, // ✅ NEVER NULL
      ),
    );
  }

  Future<void> _openChat() async {
    final token = await StorageService.getToken();
    if (token == null || widget.userId == null) return;

    try {
      final res = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/chat/get-or-create/'),
        headers: {
          'Authorization': 'Token $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'user_id': widget.userId}),
      );

      if (res.statusCode != 200) return;

      final data = jsonDecode(res.body);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            chatRoomId: data['id'],
            otherUserId: data['other_user']['id'],
            otherUsername: data['other_user']['username'],
          ),
        ),
      );
    } catch (_) {}
  }

  // ───────────────── UI ─────────────────

  @override
  Widget build(BuildContext context) {
    if (isLoading || profileData == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF00FF7F)),
        ),
      );
    }

    final username = profileData!['username'] ?? 'AnimeFan';
    final bio = profileData!['bio'] ?? 'No bio yet';
    final profileImage = profileData!['profile_image'] ?? '';
    final board = profileData!['anime_board'] ?? {};
    final postsCount = profileData!['posts_count'] ?? posts.length;
    final followersCount = profileData!['followers_count'] ?? 0;
    final followingCount = profileData!['following_count'] ?? 0;

    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.black,
      body: RefreshIndicator(
        onRefresh: _loadEverything,
        color: const Color(0xFF00FF7F),
        child: Stack(
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1E1E1E), Color(0xFF1A237E)],
                ),
              ),
            ),
            SafeArea(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // HEADER
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 40,
                              backgroundImage: profileImage.isEmpty
                                  ? const AssetImage(
                                  'assets/images/default_profile.png')
                                  : CachedNetworkImageProvider(profileImage)
                              as ImageProvider,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
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
                            if (isOwner)
                              IconButton(
                                icon: const Icon(Icons.settings,
                                    color: Color(0xFF00FF7F)),
                                onPressed: () async {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => SettingsScreen(
                                        username: username,
                                        bio: bio,
                                        profileImage: profileImage,
                                      ),
                                    ),
                                  );
                                  if (result == true) _loadEverything();
                                },
                              )
                            else
                              ElevatedButton.icon(
                                onPressed: _openChat,
                                icon: const Icon(Icons.chat),
                                label: const Text('Message'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                  const Color(0xFF00FF7F),
                                  foregroundColor: Colors.black,
                                ),
                              ),
                          ],
                        ),
                      ),

                      // ANIME BOARD
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: _animeBoardWidget(),
                      ),

                      const SizedBox(height: 16),

                      // BADGES
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text('Badges',
                            style: TextStyle(
                                color: Color(0xFF00FF7F),
                                fontSize: 18,
                                fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(height: 8),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Wrap(
                          spacing: 8,
                          children: [
                            Chip(
                                avatar: Icon(Icons.star,
                                    color: Color(0xFF00FF7F)),
                                label: Text('Top Poster')),
                            Chip(
                                avatar: Icon(Icons.book,
                                    color: Color(0xFF00FF7F)),
                                label: Text('Anime Guru')),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // STATS
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
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

                      const SizedBox(height: 16),

                      // POSTS
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: GridView.builder(
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
                          itemBuilder: (_, i) => GestureDetector(
                            onTap: () => _openPostDetail(i),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: CachedNetworkImage(
                                imageUrl: posts[i]['image'] ??
                                    Constants.placeholderImagePath,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 3),
      floatingActionButton: isOwner
          ? FloatingActionButton(
        backgroundColor: const Color(0xFF00FF7F),
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => const CreatePostScreen()),
          );
          if (result == true) _loadEverything();
        },
        child: const Icon(Icons.add, color: Colors.black),
      )
          : null,
    );
  }

  Widget _animeBoardWidget() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF00FF7F)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Anime Board',
              style: TextStyle(
                  color: Color(0xFF00FF7F),
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _getUniqueAnime().isEmpty
              ? const Text('No anime added yet',
              style: TextStyle(color: Colors.white70))
              : SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _getUniqueAnime().map((anime) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: CachedNetworkImage(
                          imageUrl: anime['thumbnail'] ??
                              Constants.placeholderImagePath,
                          width: 70,
                          height: 100,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(height: 4),
                      SizedBox(
                        width: 70,
                        child: Text(
                          anime['title'] ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 10),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stat(String value, String label) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold)),
        Text(label,
            style: const TextStyle(color: Colors.white70)),
      ],
    );
  }
}
