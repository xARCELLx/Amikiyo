import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../home/widgets/bottom_nav_bar.dart';
import '../../config/constants.dart';
import '../../services/mock_data.dart';
import '../home/widgets/post_card.dart';
import 'edit_profile_modal.dart';
import 'board_card.dart';
import '../settings/settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  String _bio = 'Loves Demon Slayer, Naruto, and One Piece';
  List<Map<String, dynamic>> _topThree = [
    {
      'id': '12191',
      'title': 'Demon Slayer',
      'thumbnail': 'https://media.kitsu.io/anime/poster_images/12191/medium.jpg',
    },
    {
      'id': '12',
      'title': 'Naruto',
      'thumbnail': 'https://media.kitsu.io/anime/poster_images/12/medium.jpg',
    },
    {
      'id': '13',
      'title': 'One Piece',
      'thumbnail': 'https://media.kitsu.io/anime/poster_images/13/medium.jpg',
    },
  ];
  List<Map<String, dynamic>> _watched = [
    {
      'id': '12191',
      'title': 'Demon Slayer',
      'thumbnail': 'https://media.kitsu.io/anime/poster_images/12191/medium.jpg',
    },
    {
      'id': '12',
      'title': 'Naruto',
      'thumbnail': 'https://media.kitsu.io/anime/poster_images/12/medium.jpg',
    },
    {
      'id': '13',
      'title': 'One Piece',
      'thumbnail': 'https://media.kitsu.io/anime/poster_images/13/medium.jpg',
    },
    {
      'id': '7442',
      'title': 'Attack on Titan',
      'thumbnail': 'https://media.kitsu.io/anime/poster_images/7442/medium.jpg',
    },
  ];
  List<Map<String, dynamic>> _nextToWatch = [];
  final int _postsCount = 15;
  final int _followersCount = 420;
  final int _followingCount = 180;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _getRank(int animeCount) {
    if (animeCount >= 50) return 'Jonin';
    if (animeCount >= 20) return 'Chunin';
    return 'Genin';
  }

  // Deduplicate anime by id for the preview
  List<Map<String, dynamic>> _getUniqueAnime() {
    final allAnime = [..._topThree, ..._watched, ..._nextToWatch];
    final seenIds = <String>{};
    final uniqueAnime = <Map<String, dynamic>>[];
    for (var anime in allAnime) {
      if (!seenIds.contains(anime['id'])) {
        seenIds.add(anime['id']);
        uniqueAnime.add(anime);
      }
    }
    debugPrint('Unique anime: $uniqueAnime');
    return uniqueAnime;
  }

  @override
  Widget build(BuildContext context) {
    final userPosts = getMockPosts().where((post) => post.username == 'AnimeFan123').toList();
    final uniqueAnime = _getUniqueAnime();
    return Scaffold(
      body: Stack(
        children: [
          // Gradient background
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [const Color(0xFF1E1E1E), const Color(0xFF1A237E).withOpacity(0.8)],
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header: PFP, Username, Settings
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          child: ClipOval(
                            child: CachedNetworkImage(
                              imageUrl: 'https://picsum.photos/150/150?random=5',
                              fit: BoxFit.cover,
                              placeholder: (context, url) => const CircularProgressIndicator(
                                color: Color(0xFF00FF7F),
                              ),
                              errorWidget: (context, url, error) {
                                debugPrint('Profile image failed: $url, error: $error');
                                return Image.asset(
                                  Constants.defaultProfilePath,
                                  fit: BoxFit.cover,
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'AnimeFan123',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  color: Colors.white,
                                  fontFamily: 'AnimeAce',
                                  fontWeight: FontWeight.w600,
                                  shadows: [
                                    Shadow(
                                      blurRadius: 4,
                                      color: Colors.black.withOpacity(0.3),
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 4),
                              GestureDetector(
                                onTap: () async {
                                  final result = await showModalBottomSheet<Map<String, dynamic>>(
                                    context: context,
                                    isScrollControlled: true,
                                    builder: (context) => const EditProfileModal(),
                                  );
                                  if (result != null) {
                                    setState(() {
                                      _bio = result['bio'];
                                    });
                                  }
                                },
                                child: Text(
                                  _bio,
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.white70,
                                    fontFamily: 'AnimeAce',
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.settings, color: Color(0xFF00FF7F)),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const SettingsScreen()),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Anime Board Preview
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: GestureDetector(
                      onTap: () async {
                        debugPrint('Opening BoardCard with Hero animation');
                        final result = await showDialog<Map<String, dynamic>>(
                          context: context,
                          builder: (context) => Stack(
                            children: [
                              // Blur the background
                              BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                                child: Container(
                                  color: Colors.black.withOpacity(0.5),
                                ),
                              ),
                              Dialog(
                                backgroundColor: Colors.transparent,
                                insetPadding: const EdgeInsets.all(16),
                                child: BoardCard(
                                  topThree: _topThree,
                                  watched: _watched,
                                  nextToWatch: _nextToWatch,
                                ),
                              ),
                            ],
                          ),
                        );
                        debugPrint('BoardCard closed with result: $result');
                        if (result != null) {
                          setState(() {
                            _topThree = result['topThree'];
                            _watched = result['watched'];
                            _nextToWatch = result['nextToWatch'];
                            // Ensure Top 3 Favorites are in Watched Anime
                            for (var anime in _topThree) {
                              if (!_watched.any((w) => w['id'] == anime['id'])) {
                                _watched.add(anime);
                              }
                            }
                          });
                        }
                      },
                      child: Hero(
                        tag: 'anime_board',
                        child: Material(
                          color: Colors.transparent,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0xFF00FF7F), width: 1),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Anime Board',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: const Color(0xFF00FF7F),
                                    fontFamily: 'AnimeAce',
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                uniqueAnime.isEmpty
                                    ? Text(
                                  'No anime added yet',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.white70,
                                    fontFamily: 'AnimeAce',
                                    fontWeight: FontWeight.w400,
                                  ),
                                )
                                    : SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    children: uniqueAnime.map((anime) => Padding(
                                      padding: const EdgeInsets.only(right: 8),
                                      child: Column(
                                        children: [
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(6),
                                            child: CachedNetworkImage(
                                              imageUrl: anime['thumbnail'] ?? Constants.placeholderImagePath,
                                              width: 70,
                                              height: 100,
                                              fit: BoxFit.cover,
                                              placeholder: (context, url) => const CircularProgressIndicator(
                                                color: Color(0xFF00FF7F),
                                              ),
                                              errorWidget: (context, url, error) {
                                                debugPrint('Anime thumbnail failed: $url, error: $error');
                                                return Image.asset(
                                                  Constants.placeholderImagePath,
                                                  width: 70,
                                                  height: 100,
                                                  fit: BoxFit.cover,
                                                );
                                              },
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          SizedBox(
                                            width: 70,
                                            child: Text(
                                              anime['title'],
                                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                color: Colors.white,
                                                fontFamily: 'AnimeAce',
                                                fontWeight: FontWeight.w400,
                                              ),
                                              textAlign: TextAlign.center,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    )).toList(),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Rank
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFF00FF7F), width: 1),
                      ),
                      child: Text(
                        'Rank: ${_getRank(_watched.length)} (${_watched.length} anime watched)',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontFamily: 'AnimeAce',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Badges
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Badges',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: const Color(0xFF00FF7F),
                            fontFamily: 'AnimeAce',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        FadeTransition(
                          opacity: _fadeAnimation,
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              {'name': 'Top Poster', 'icon': Icons.star},
                              {'name': 'Cosplay Pro', 'icon': Icons.camera},
                              {'name': 'Anime Guru', 'icon': Icons.book},
                            ].map((badge) => Chip(
                              avatar: Icon(badge['icon'] as IconData, color: const Color(0xFF00FF7F), size: 18),
                              label: Text(
                                badge['name'] as String,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.white,
                                  fontFamily: 'AnimeAce',
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                              backgroundColor: Colors.white.withOpacity(0.1),
                              side: const BorderSide(color: Color(0xFF00FF7F)),
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                            )).toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Stats (Posts, Followers, Following)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFF00FF7F), width: 1),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Column(
                            children: [
                              Text(
                                _postsCount.toString(),
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Colors.white,
                                  fontFamily: 'AnimeAce',
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                'Posts',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.white70,
                                  fontFamily: 'AnimeAce',
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            children: [
                              Text(
                                _followersCount.toString(),
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Colors.white,
                                  fontFamily: 'AnimeAce',
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                'Followers',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.white70,
                                  fontFamily: 'AnimeAce',
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            children: [
                              Text(
                                _followingCount.toString(),
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Colors.white,
                                  fontFamily: 'AnimeAce',
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                'Following',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.white70,
                                  fontFamily: 'AnimeAce',
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Posts Grid
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'My Posts',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: const Color(0xFF00FF7F),
                            fontFamily: 'AnimeAce',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        userPosts.isEmpty
                            ? Center(
                          child: Text(
                            'No posts yet',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.white70,
                              fontFamily: 'AnimeAce',
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        )
                            : GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                            childAspectRatio: 1,
                          ),
                          itemCount: userPosts.length,
                          itemBuilder: (context, index) => GestureDetector(
                            onTap: () {}, // TODO: Navigate to post details
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: CachedNetworkImage(
                                imageUrl: userPosts[index].imageUrl ?? Constants.placeholderImagePath,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => const CircularProgressIndicator(
                                  color: Color(0xFF00FF7F),
                                ),
                                errorWidget: (context, url, error) {
                                  debugPrint('Post image failed: $url, error: $error');
                                  return Image.asset(
                                    Constants.placeholderImagePath,
                                    fit: BoxFit.cover,
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavBar(currentIndex: 3),
    );
  }
}