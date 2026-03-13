// lib/src/screens/profile/profile_screen.dart

import 'dart:convert';
import 'dart:ui';

import 'package:amikiyo/src/screens/follow/following_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../follow/followers_screen.dart';
import '../home/widgets/bottom_nav_bar.dart';
import '../../config/constants.dart';
import '../../services/api_service.dart';
import '../../services/storage_service.dart';
import '../../services/constants.dart';
import '../chat/chat_screen.dart';
import '../home/widgets/thought_viewer.dart';
import './board_card.dart';
import '../settings/settings_screen.dart';
import '../post_creation/create_post_screen.dart';
import 'post_detail_modal.dart';
import '../../widgets/create_post_fab/create_post_fab.dart';

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

  /// 🔐 FINAL SOURCE OF TRUTH FOR UI POSTS
  /// 🔐 FINAL SOURCE OF TRUTH FOR UI POSTS
  List<Map<String, dynamic>> get visiblePosts {
    if (isOwner) {
      return List<Map<String, dynamic>>.from(posts);
    }
    return posts
        .where((p) => p['privacy'] == 'public')
        .map<Map<String, dynamic>>(
          (p) => Map<String, dynamic>.from(p),
    )
        .toList();
  }

  /// ───────────────── IMAGE POSTS ─────────────────
  /// Only image posts (used in grid)
  List<Map<String, dynamic>> get imagePosts {
    return visiblePosts
        .where((p) => p['post_type'] != 'thought')
        .map<Map<String, dynamic>>((p) => Map<String, dynamic>.from(p))
        .toList();
  }

  /// ───────────────── THOUGHT POSTS ─────────────────
  /// Text thoughts only
  List<Map<String, dynamic>> get thoughtPosts {
    return visiblePosts
        .where((p) => p['post_type'] == 'thought')
        .map<Map<String, dynamic>>((p) => Map<String, dynamic>.from(p))
        .toList();
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
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

  void _openPostDetail(Map<String, dynamic> post) {
    if (!isOwner && post['privacy'] != 'public') return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PostDetailModal(
        post: post,
        heroTag: 'post_${post['id']}',
        onDelete: isOwner
            ? () {
          if (!mounted) return;
          setState(() {
            posts.removeWhere((p) => p['id'] == post['id']);
          });
        }
            : null,
        onUpdate: isOwner ? _loadEverything : null,
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
            chatType: ChatType.private,
            otherUserId: data['other_user']['id'],
            title: data['other_user']['username'],
          ),
        ),
      );
    } catch (_) {}
  }

  Future<void> _toggleFollow() async {
    if (widget.userId == null) return;

    final token = await StorageService.getToken();
    if (token == null) return;

    final bool isFollowing = profileData?['is_following'] ?? false;

    final url = isFollowing
        ? '${ApiConstants.baseUrl}/profiles/${widget.userId}/unfollow/'
        : '${ApiConstants.baseUrl}/profiles/${widget.userId}/follow/';

    final res = await http.post(
      Uri.parse(url),
      headers: {
        'Authorization': 'Token $token',
        'Content-Type': 'application/json',
      },
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      setState(() {
        profileData!['is_following'] = data['followed'];
        profileData!['followers_count'] = data['followers_count'];
      });
    }
  }

  // ───────────────── UI ─────────────────

  @override
  Widget build(BuildContext context) {
    if (isLoading || profileData == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFFFFFFFF)),
        ),
      );
    }

    final username = profileData!['username'] ?? 'AnimeFan';
    final bio = profileData!['bio'] ?? 'No bio yet';
    final profileImage = profileData!['profile_image'] ?? '';
    final board = profileData!['anime_board'] ?? {};
    final postsCount = imagePosts.length;
    final followersCount = profileData!['followers_count'] ?? 0;
    final followingCount = profileData!['following_count'] ?? 0;

    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.black,
      body: RefreshIndicator(
        onRefresh: _loadEverything,
        color: const Color(0xFFFFFFFF),
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
                                    color: Color(0xFFFFFFFF)),
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
                              ),
                          ],
                        ),
                      ),

                      // ANIME BOARD
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: GestureDetector(
                          onTap: () async {
                            final result =
                            await showDialog<Map<String, dynamic>>(
                              context: context,
                              builder: (_) => Stack(
                                children: [
                                  BackdropFilter(
                                    filter: ImageFilter.blur(
                                        sigmaX: 6, sigmaY: 6),
                                    child: Container(color: Colors.black54),
                                  ),
                                  Dialog(
                                    backgroundColor: Colors.transparent,
                                    child: BoardCard(
                                      topThree:
                                      List.from(board['top_three'] ?? []),
                                      watched:
                                      List.from(board['watched'] ?? []),
                                      nextToWatch: List.from(
                                          board['next_to_watch'] ?? []),
                                      isEditable: isOwner,
                                    ),
                                  ),
                                ],
                              ),
                            );

                            if (!isOwner || result == null) return;

                            final updatedBoard = {
                              'top_three': result['topThree'] ?? [],
                              'watched': result['watched'] ?? [],
                              'next_to_watch': result['nextToWatch'] ?? [],
                            };

                            setState(() {
                              profileData!['anime_board'] = updatedBoard;
                            });

                            final token =
                            await StorageService.getToken();
                            await http.patch(
                              Uri.parse(
                                  '${ApiConstants.baseUrl}/profiles/me/'),
                              headers: {
                                'Authorization': 'Token $token',
                                'Content-Type': 'application/json',
                              },
                              body: jsonEncode(
                                  {'anime_board': updatedBoard}),
                            );
                          },
                          child: _animeBoardWidget(),
                        ),
                      ),

                      // ACTION ROW
                      if (!isOwner)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          child: Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: _toggleFollow,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                    profileData!['is_following']
                                        ? Colors.grey[800]
                                        : const Color(0xFFFFFFFF),
                                    foregroundColor: Colors.black,
                                  ),
                                  child: Text(
                                      profileData!['is_following']
                                          ? 'Following'
                                          : 'Follow'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _openChat,
                                  icon: const Icon(Icons.chat),
                                  label: const Text('Message'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    side: const BorderSide(
                                        color: Color(0xFFFFFFFF)),
                                  ),
                                ),
                              ),
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
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => FollowersScreen(
                                      userId: widget.userId ??
                                          profileData!['user_id'],
                                    ),
                                  ),
                                );
                              },
                              child:
                              _stat('$followersCount', 'Followers'),
                            ),
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => FollowingScreen(
                                      userId: widget.userId ??
                                          profileData!['user_id'],
                                    ),
                                  ),
                                );
                              },
                              child:
                              _stat('$followingCount', 'Following'),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // POSTS GRID
    if (imagePosts.isNotEmpty)
    Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate:
          const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          ),
          itemCount: imagePosts.length,
          itemBuilder: (_, i) {
          final post = imagePosts[i];

          return GestureDetector(
          onTap: () => _openPostDetail(post),
          child: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: CachedNetworkImage(
          imageUrl: post['image'] ??
          Constants.placeholderImagePath,
          fit: BoxFit.cover,
          ),
          ),
          );
        },
      ),

    ),
                      // ───────────────── SHARED THOUGHTS ─────────────────

                      if (thoughtPosts.isNotEmpty) ...[

                        const SizedBox(height: 28),

                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            "Shared Thoughts",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'AnimeAce',
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: thoughtPosts.length,
                          separatorBuilder: (_, __) => const Divider(
                            color: Colors.white12,
                            height: 24,
                          ),
                          itemBuilder: (_, i) {

                            final thought = thoughtPosts[i];
                            final caption = thought['caption'] ?? '';
                            final anime = thought['anime_title'];

                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: GestureDetector(
                                onTap: () {
                                  showGeneralDialog(
                                    context: context,
                                    barrierDismissible: true,
                                    barrierColor: Colors.black54,
                                    pageBuilder: (_, __, ___) {
                                      return ThoughtViewer(post: thought);
                                    },
                                  );
                                },
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [

                                    Text(
                                      caption,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        height: 1.4,
                                      ),
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                    ),

                                    if (anime != null) ...[
                                      const SizedBox(height: 6),
                                      Text(
                                        anime,
                                        style: const TextStyle(
                                          color: Color(0xFF00FF7F),
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            );
                          },
                        ),

                      ],

                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar:
      const BottomNavBar(currentIndex: 3),
      floatingActionButton: isOwner
          ? CreatePostFab(
        onPostCreated: _loadEverything,
      )
          : null,
    );
  }

  // ───────────────── WIDGETS ─────────────────

  Widget _animeBoardWidget() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFFFFFFF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Anime Board',
              style: TextStyle(
                  color: Color(0xFFFFFFFF),
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
                  padding:
                  const EdgeInsets.only(right: 8),
                  child: Column(
                    children: [
                      ClipRRect(
                        borderRadius:
                        BorderRadius.circular(6),
                        child: CachedNetworkImage(
                          imageUrl:
                          anime['thumbnail'] ??
                              Constants
                                  .placeholderImagePath,
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
                          overflow:
                          TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10),
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
            style:
            const TextStyle(color: Colors.white70)),
      ],
    );
  }
}
