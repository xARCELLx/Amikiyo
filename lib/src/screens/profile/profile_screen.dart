// lib/src/screens/profile/profile_screen.dart
import 'dart:convert';
import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../home/widgets/bottom_nav_bar.dart';
import '../../config/constants.dart';
import '../../services/api_service.dart';
import '../../services/storage_service.dart';
import '../../services/constants.dart';
import './board_card.dart';
import '../settings/settings_screen.dart';
import '../post_creation/create_post_screen.dart';
import 'post_detail_modal.dart'; // ← NEW MODAL

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  Map<String, dynamic>? profileData;
  List<dynamic> posts = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(milliseconds: 1000), vsync: this);
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));
    _loadEverything();
  }

  Future<void> _loadEverything() async {
    if (!mounted) return;
    setState(() => isLoading = true);

    Map<String, dynamic>? data;
    for (int i = 0; i < 5; i++) {
      data = await ApiService.getMyProfile();
      if (data != null) break;
      await Future.delayed(const Duration(milliseconds: 800));
    }

    List<dynamic> fetchedPosts = [];
    if (data != null) {
      try {
        final token = await StorageService.getToken();
        final response = await http.get(
          Uri.parse('${ApiConstants.baseUrl}/posts/user/me/'),
          headers: {'Authorization': 'Token $token'},
        );
        if (response.statusCode == 200) {
          fetchedPosts = jsonDecode(response.body);
        }
      } catch (e) {
        debugPrint('Failed to load posts: $e');
      }
    }

    if (mounted) {
      setState(() {
        profileData = data;
        posts = fetchedPosts;
        isLoading = false;
      });
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _getRank(int watchedCount) {
    if (watchedCount >= 50) return 'Jonin';
    if (watchedCount >= 20) return 'Chunin';
    return 'Genin';
  }

  List<Map<String, dynamic>> _getUniqueAnime() {
    if (profileData == null) return [];
    final board = profileData!['anime_board'] ?? {};
    final List<dynamic> all = [
      ...(board['top_three'] ?? []),
      ...(board['watched'] ?? []),
      ...(board['next_to_watch'] ?? []),
    ];
    final seen = <String>{};
    final List<Map<String, dynamic>> unique = [];
    for (var anime in all) {
      final id = anime['id']?.toString() ?? '';
      if (id.isNotEmpty && !seen.contains(id) && anime is Map<String, dynamic>) {
        seen.add(id);
        unique.add(anime);
      }
    }
    return unique;
  }

  void _showFollowersModal() => showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (_) => _buildModal('Followers', 'No followers yet'));
  void _showFollowingModal() => showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (_) => _buildModal('Following', 'Not following anyone yet'));

  Widget _buildModal(String title, String emptyText) {
    return Stack(
      children: [
        BackdropFilter(filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5), child: Container(color: Colors.black.withOpacity(0.5))),
        Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            height: MediaQuery.of(context).size.height * 0.5,
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: const BorderRadius.vertical(top: Radius.circular(6)), border: Border.all(color: Color(0xFF00FF7F), width: 1)),
            child: Column(children: [
              Container(width: 40, height: 4, margin: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.white54, borderRadius: BorderRadius.circular(2))),
              Padding(padding: const EdgeInsets.all(12), child: Text(title, style: const TextStyle(color: Color(0xFF00FF7F), fontSize: 18, fontWeight: FontWeight.bold))),
              const Divider(color: Color(0xFF00FF7F), height: 1),
              Expanded(child: Center(child: Text(emptyText, style: const TextStyle(color: Colors.white70)))),
            ]),
          ),
        ),
      ],
    );
  }

  void _openPostDetail(int index) {
    final post = posts[index];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PostDetailModal(
        post: post,
        heroTag: 'post_$index',
        onDelete: () {
          if (!mounted) return;
          setState(() {
            posts.removeAt(index);
          });
        },
        onUpdate: _loadEverything,
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    if (isLoading || profileData == null) {
      return const Scaffold(backgroundColor: Colors.black, body: Center(child: CircularProgressIndicator(color: Color(0xFF00FF7F))));
    }

    final String username = profileData!['username'] ?? 'AnimeFan';
    final String bio = profileData!['bio'] ?? 'No bio yet';
    final String profileImage = profileData!['profile_image'] ?? '';
    final Map<String, dynamic> board = (profileData!['anime_board'] ?? {}) as Map<String, dynamic>;
    final int watchedCount = (board['watched'] as List?)?.length ?? 0;
    final int postsCount = profileData!['posts_count'] ?? posts.length;
    final int followersCount = profileData!['followers_count'] ?? 0;
    final int followingCount = profileData!['following_count'] ?? 0;

    return Scaffold(
      extendBody: true,
      body: RefreshIndicator(
        onRefresh: _loadEverything,
        color: const Color(0xFF00FF7F),
        child: Stack(
          children: [
            Container(decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF1E1E1E), Color(0xFF1A237E)]))),
            SafeArea(
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                  // HEADER
                  Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(children: [
                    Hero(tag: 'profile_image', child: CircleAvatar(radius: 40, backgroundColor: Colors.transparent, child: ClipOval(child: profileImage.isEmpty ? Image.asset('assets/images/default_profile.png', fit: BoxFit.cover) : CachedNetworkImage(imageUrl: profileImage, fit: BoxFit.cover, placeholder: (_, __) => Container(color: Colors.grey[800], child: const CircularProgressIndicator(color: Color(0xFF00FF7F))), errorWidget: (_, __, ___) => Image.asset('assets/images/default_profile.png'))))),
                    const SizedBox(width: 16),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(username, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'AnimeAce')), const SizedBox(height: 4), Text(bio, style: const TextStyle(color: Colors.white70, fontFamily: 'AnimeAce'))])),
                    IconButton(icon: const Icon(Icons.settings, color: Color(0xFF00FF7F)), onPressed: () async { final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => SettingsScreen(username: username, bio: bio, profileImage: profileImage))); if (result == true) await _loadEverything(); }),
                  ]),
                ),

                // ANIME BOARD
                Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: GestureDetector(onTap: () async {
                  final result = await showDialog<Map<String, dynamic>>(context: context, builder: (_) => Stack(children: [BackdropFilter(filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5), child: Container(color: Colors.black.withOpacity(0.5))), Dialog(backgroundColor: Colors.transparent, child: BoardCard(topThree: List.from(board['top_three'] ?? []), watched: List.from(board['watched'] ?? []), nextToWatch: List.from(board['next_to_watch'] ?? [])))]));
                  if (result != null) {
                    final token = await StorageService.getToken();
                    final response = await http.patch(Uri.parse('${ApiConstants.baseUrl}/profiles/me/'), headers: {'Authorization': 'Token $token', 'Content-Type': 'application/json'}, body: jsonEncode({'anime_board': {'top_three': result['topThree'] ?? [], 'watched': result['watched'] ?? [], 'next_to_watch': result['nextToWatch'] ?? []}}));
                    if (response.statusCode == 200) { await _loadEverything(); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Anime Board Saved!'), backgroundColor: Color(0xFF00FF7F))); }
                  }
                }, child: Hero(tag: 'anime_board', child: Container(width: double.infinity, padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(6), border: Border.all(color: const Color(0xFF00FF7F))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Anime Board', style: TextStyle(color: Color(0xFF00FF7F), fontSize: 18, fontWeight: FontWeight.bold)), const SizedBox(height: 8), _getUniqueAnime().isEmpty ? const Text('No anime added yet', style: TextStyle(color: Colors.white70)) : SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: _getUniqueAnime().map((anime) => Padding(padding: const EdgeInsets.only(right: 8), child: Column(children: [ClipRRect(borderRadius: BorderRadius.circular(6), child: CachedNetworkImage(imageUrl: anime['thumbnail'] ?? Constants.placeholderImagePath, width: 70, height: 100, fit: BoxFit.cover)), const SizedBox(height: 4), SizedBox(width: 70, child: Text(anime['title'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 10), textAlign: TextAlign.center, overflow: TextOverflow.ellipsis))]))).toList()))]))))),
                const SizedBox(height: 12),

                // RANK + BADGES + STATS (unchanged)
                Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Container(width: double.infinity, padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(6), border: Border.all(color: const Color(0xFF00FF7F))), child: Text('Rank: ${_getRank(watchedCount)} ($watchedCount anime watched)', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)))),
                const SizedBox(height: 12),
                const Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Badges', style: TextStyle(color: Color(0xFF00FF7F), fontSize: 18, fontWeight: FontWeight.bold)), SizedBox(height: 8), Wrap(spacing: 8, children: [Chip(avatar: Icon(Icons.star, color: Color(0xFF00FF7F)), label: Text('Top Poster'), backgroundColor: Colors.white10, side: BorderSide(color: Color(0xFF00FF7F))), Chip(avatar: Icon(Icons.camera, color: Color(0xFF00FF7F)), label: Text('Cosplay Pro'), backgroundColor: Colors.white10, side: BorderSide(color: Color(0xFF00FF7F))), Chip(avatar: Icon(Icons.book, color: Color(0xFF00FF7F)), label: Text('Anime Guru'), backgroundColor: Colors.white10, side: BorderSide(color: Color(0xFF00FF7F)))])])),
            const SizedBox(height: 12),
            Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(6), border: Border.all(color: const Color(0xFF00FF7F))), child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [_stat('$postsCount', 'Posts'), GestureDetector(onTap: _showFollowersModal, child: _stat('$followersCount', 'Followers')), GestureDetector(onTap: _showFollowingModal, child: _stat('$followingCount', 'Following'))]))),
            const SizedBox(height: 12),

            // MY POSTS
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('My Posts', style: TextStyle(color: Color(0xFF00FF7F), fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  posts.isEmpty
                      ? const Center(child: Text('No posts yet', style: TextStyle(color: Colors.white70)))
                      : GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 8, mainAxisSpacing: 8),
                    itemCount: posts.length,
                    itemBuilder: (context, i) => GestureDetector(
                      onTap: () => _openPostDetail(i),
                      child: Hero(
                        tag: 'post_$i',
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: CachedNetworkImage(
                            imageUrl: posts[i]['image'] ?? Constants.placeholderImagePath,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Container(color: Colors.grey[800]),
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
    bottomNavigationBar: const BottomNavBar(currentIndex: 3),
    floatingActionButton: FloatingActionButton(
    backgroundColor: const Color(0xFF00FF7F),
    child: const Icon(Icons.add, color: Colors.black),
    onPressed: () async {
    final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => const CreatePostScreen()));
    if (result == true) await _loadEverything();
    },
    ),
    floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _stat(String value, String label) => Column(children: [Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)), Text(label, style: const TextStyle(color: Colors.white70))]);
}